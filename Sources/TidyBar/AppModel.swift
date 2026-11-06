import AppKit
import SwiftUI
import ServiceManagement
import TidyBarCore

struct SelectableApp: Identifiable {
    let id: String
    let name: String
    let icon: NSImage?
    let isRunning: Bool
    let applicationPath: String?
}

@MainActor
final class AppModel: ObservableObject {
    let usesNative = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27
    @Published private(set) var isHidden = false
    @Published private(set) var wantsHidden = false
    @Published private(set) var nativeState: NativeVisibilityState = .expanded
    @Published private(set) var applications: [SelectableApp] = []
    @Published private(set) var hiddenBundleIDs: Set<String>
    @Published var nativeEnabled: Bool {
        didSet {
            defaults.set(nativeEnabled, forKey: "nativeVisibilityEnabledV1")
            if !nativeEnabled { setHidden(false) }
            else {
                if case .failed = nativeState {} else { visibilityError = nil }
                onVisibilityChange?(isHidden)
                reschedule()
            }
        }
    }
    @Published var autoHideDelay: Int { didSet { defaults.set(autoHideDelay, forKey: "autoHideDelay"); reschedule() } }
    @Published var hideAtLaunch: Bool { didSet { defaults.set(hideAtLaunch, forKey: "hideAtLaunch") } }
    @Published private(set) var loginEnabled = false
    @Published private(set) var loginNeedsApproval = false
    @Published var loginError: String?
    @Published var visibilityError: String?
    @Published var shortcutAvailable = true
    @Published private(set) var trialActive = false
    var onVisibilityChange: ((Bool) -> Void)?
    private let defaults: UserDefaults
    private let native = NativeVisibilityCoordinator(backend: NativeMenuBarBackend())
    private var policy = VisibilityPolicy()
    private var timer: Timer?
    private var activationTimeout: Timer?
    private var trialTimer: Timer?
    private var settingsOpen = false
    private var runningObservation: NSKeyValueObservation?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var knownNames: [String: String]
    private var runningIDs: Set<String> = []
    private let own = Bundle.main.bundleIdentifier ?? "com.tidybar.app"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.integer(forKey: "autoHideDelay")
        autoHideDelay = [0, 10, 30, 60].contains(stored) ? stored : 0
        hideAtLaunch = defaults.bool(forKey: "hideAtLaunch")
        nativeEnabled = defaults.bool(forKey: "nativeVisibilityEnabledV1")
        hiddenBundleIDs = Set(defaults.stringArray(forKey: "hiddenBundleIDsV1") ?? [])
        knownNames = defaults.dictionary(forKey: "knownAppNamesV1") as? [String: String] ?? [:]
        hiddenBundleIDs.remove(own)
        native.onChange = { [weak self] state in self?.nativeChanged(state) }
        refreshApplications()
        refreshLoginStatus()
        // KVO catches agent launches that don't emit ordinary launch events.
        runningObservation = NSWorkspace.shared.observe(\.runningApplications, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in self?.refreshApplications() }
        }
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.activeSpaceDidChangeNotification] {
            workspaceObservers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.refreshApplications()
                    // An explicit reveal after wake/space change avoids a stale
                    // system restriction spanning an untested session change.
                    self.setHidden(false)
                }
            })
        }
    }

    var nativeUnavailableReason: String? {
        if !Bundle.main.bundleURL.path.hasPrefix("/Applications/") {
            return "Run the updated Tidy Bar from /Applications before hiding, so macOS keeps the cat available."
        }
        return NativeMenuBarBackend().unavailableReason
    }

    var stateLabel: String {
        if !usesNative { return isHidden ? "Tucked away" : "Expanded" }
        switch nativeState {
        case .preparing: return "Preparing…"
        case .active: return trialActive ? "Trial · restores after 10s" : "Native hiding active"
        case .failed: return "Needs attention"
        case .expanded: return wantsHidden ? "Waiting for selected apps" : "Expanded"
        }
    }

    func setAppHidden(_ id: String, hidden: Bool) {
        guard id != own, !id.hasPrefix("com.apple.") else { return }
        if hidden { hiddenBundleIDs.insert(id) }
        else { hiddenBundleIDs.remove(id) }
        defaults.set(hiddenBundleIDs.sorted(), forKey: "hiddenBundleIDsV1")
        if case .failed = nativeState {} else {
            visibilityError = nil
            onVisibilityChange?(isHidden)
        }
        if wantsHidden { applyNative() }
    }

    func refreshApplications() {
        let running = NSWorkspace.shared.runningApplications
        let nextIDs = Set(running.compactMap(\.bundleIdentifier))
        let changed = nextIDs != runningIDs
        runningIDs = nextIDs
        var byID: [String: NSRunningApplication] = [:]
        for app in running {
            guard let id = app.bundleIdentifier, id != own, !id.hasPrefix("com.apple."),
                  app.activationPolicy != .prohibited else { continue }
            byID[id] = app
            knownNames[id] = app.localizedName ?? id
        }
        // Keep saved choices even after an app exits. Unselected historical
        // helper processes need not clutter the settings list.
        let ids = Set(byID.keys).union(hiddenBundleIDs)
        applications = ids.map { id in
            let app = byID[id]
            return SelectableApp(id: id, name: app?.localizedName ?? knownNames[id] ?? id,
                                 icon: app?.icon, isRunning: nextIDs.contains(id),
                                 applicationPath: app?.bundleURL?.path)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        defaults.set(knownNames, forKey: "knownAppNamesV1")
        if usesNative && wantsHidden && changed { applyNative() }
    }

    func toggle() { setHidden(!(usesNative ? wantsHidden : isHidden)) }

    func setHidden(_ hidden: Bool) {
        timer?.invalidate()
        timer = nil
        if usesNative {
            wantsHidden = hidden
            if hidden { applyNative() }
            else {
                trialTimer?.invalidate()
                trialTimer = nil
                trialActive = false
                native.reveal()
            }
        } else {
            isHidden = hidden
            wantsHidden = hidden
            policy.setHidden(hidden)
            onVisibilityChange?(hidden)
        }
        reschedule()
    }

    func runTrial() {
        trialTimer?.invalidate()
        trialActive = true
        setHidden(true)
        // Bound the entire trial, including time spent preparing.
        guard wantsHidden else { trialActive = false; return }
        trialTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.setHidden(false) }
        }
    }

    private func applyNative() {
        guard nativeEnabled else { refuse("Enable native hiding below, then choose the apps to tuck away."); return }
        guard !hiddenBundleIDs.isEmpty else { refuse("Choose at least one app to hide."); return }
        if let reason = nativeUnavailableReason { refuse(reason); return }
        // Without Accessibility we cannot distinguish an app with no status
        // item from one whose icon must remain visible. Refuse known outside-
        // Applications candidates rather than silently suppressing them.
        let outside = applications.filter {
            $0.isRunning && !hiddenBundleIDs.contains($0.id)
                && !($0.applicationPath?.hasPrefix("/Applications/") ?? false)
        }
        if !outside.isEmpty {
            refuse("macOS may also hide these apps because they run outside /Applications: \(outside.map(\.name).joined(separator: ", ")). Move them into /Applications or select them to hide before trying again.")
            return
        }
        native.hide(running: runningIDs, hidden: hiddenBundleIDs, own: own)
    }

    private func refuse(_ message: String) {
        wantsHidden = false
        native.reveal()
        if case .failed(let error) = nativeState { visibilityError = error }
        else { visibilityError = message }
        onVisibilityChange?(isHidden)
        trialTimer?.invalidate()
        trialTimer = nil
        trialActive = false
        reschedule()
    }

    private func nativeChanged(_ state: NativeVisibilityState) {
        activationTimeout?.invalidate()
        activationTimeout = nil
        nativeState = state
        isHidden = state == .active
        visibilityError = nil
        if case .failed(let message) = state {
            wantsHidden = false
            visibilityError = message
            trialTimer?.invalidate()
            trialTimer = nil
            trialActive = false
        }
        if state == .preparing {
            let ticket = native.revision
            activationTimeout = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.native.timeout(ticket: ticket) }
            }
        }
        policy.setHidden(isHidden)
        onVisibilityChange?(isHidden)
        reschedule()
    }

    func setSettingsOpen(_ open: Bool) {
        settingsOpen = open
        if open { refreshLoginStatus(); refreshApplications() }
        reschedule()
    }

    private func reschedule() {
        timer?.invalidate()
        timer = nil
        policy.configure(delay: autoHideDelay, suspended: settingsOpen)
        guard !wantsHidden, visibilityError == nil, let ticket = policy.timerTicket else { return }
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(autoHideDelay), repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.policy.autoHide(ticket: ticket) else { return }
                self.setHidden(true)
            }
        }
    }

    func shutdown() {
        native.onChange = nil
        timer?.invalidate()
        activationTimeout?.invalidate()
        trialTimer?.invalidate()
        runningObservation?.invalidate()
        for observer in workspaceObservers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        workspaceObservers.removeAll()
        wantsHidden = false
        native.reveal()
    }

    func refreshLoginStatus() {
        let status = SMAppService.mainApp.status
        loginEnabled = status == .enabled || status == .requiresApproval
        loginNeedsApproval = status == .requiresApproval
    }

    func setLoginEnabled(_ enabled: Bool) {
        loginError = nil
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            loginError = "Couldn’t update login startup: \(error.localizedDescription)"
        }
        refreshLoginStatus()
    }
}
