import AppKit
import TidyBarCore

@MainActor
final class StatusBarController: NSObject {
    private let model: AppModel
    private let control: NSStatusItem
    private var divider: NSStatusItem?
    private var screenObserver: NSObjectProtocol?
    var onOpenSettings: (() -> Void)?

    init(model: AppModel) {
        self.model = model
        control = NSStatusBar.system.statusItem(withLength: 30)
        // Preserve the cat's placement from the overflow version. macOS 27
        // creates no divider or helper spacers in this implementation.
        control.autosaveName = model.usesNative ? "TidyBar.OverflowV1.Control" : "TidyBar.Control"
        if !model.usesNative {
            let item = NSStatusBar.system.statusItem(withLength: 22)
            item.autosaveName = "TidyBar.Divider"
            item.button?.title = "│"
            item.button?.toolTip = "Hold ⌘ and drag icons left of the divider. Keep the cat on its right."
            divider = item
        }
        super.init()
        if let button = control.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityLabel("Tidy Bar")
        }
        model.onVisibilityChange = { [weak self] hidden in self?.apply(hidden: hidden) }
        apply(hidden: false)
        screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.model.setHidden(false) }
        }
    }

    private func apply(hidden: Bool) {
        if let divider {
            let layout = SpacerLayout.make(displays: NSScreen.screens.map { .init(width: Double($0.frame.width)) }, modern: false)
            if hidden && !layout.coversAllDisplays {
                model.setHidden(false)
                model.visibilityError = "This display layout is unsupported. Icons have been expanded."
                return
            }
            divider.length = hidden ? CGFloat(layout.widths[0]) : 22
        }
        if model.visibilityError != nil || { if case .failed = model.nativeState { return true }; return false }() {
            control.button?.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Hiding needs attention")
        } else {
            control.button?.image = CatArtwork.menuImage(hidden: hidden)
        }
        control.button?.toolTip = model.visibilityError ?? "Tidy Bar · \(model.stateLabel) · Click to \(model.wantsHidden ? "show" : "hide") apps (⌥⌘B)"
        control.button?.setAccessibilityValue(model.stateLabel)
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp { showMenu() }
        else { model.toggle() }
    }

    private func showMenu() {
        let menu = NSMenu()
        let title = NSMenuItem(title: "Tidy Bar · \(model.stateLabel)", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())
        let toggle = NSMenuItem(title: model.wantsHidden ? "Show everything" : "Hide selected apps", action: #selector(toggleFromMenu), keyEquivalent: "b")
        toggle.keyEquivalentModifierMask = [.command, .option]
        toggle.target = self
        menu.addItem(toggle)
        let restore = NSMenuItem(title: "Show everything", action: #selector(restoreAll), keyEquivalent: "")
        restore.target = self
        menu.addItem(restore)
        if model.usesNative {
            let trial = NSMenuItem(title: "Try hiding for 10 seconds", action: #selector(tryHiding), keyEquivalent: "")
            trial.target = self
            menu.addItem(trial)
        }
        let settings = NSMenuItem(title: "Settings & apps…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Tidy Bar", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        control.menu = menu
        control.button?.performClick(nil)
        control.menu = nil
    }

    @objc private func toggleFromMenu() { model.toggle() }
    @objc private func restoreAll() { model.setHidden(false) }
    @objc private func tryHiding() { model.runTrial() }
    @objc private func openSettings() { onOpenSettings?() }
    @objc private func quitApp() { NSApp.terminate(nil) }

    func tearDown() {
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        model.onVisibilityChange = nil
        model.shutdown()
        if let divider { NSStatusBar.system.removeStatusItem(divider) }
        NSStatusBar.system.removeStatusItem(control)
    }
}
