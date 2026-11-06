import AppKit
import SwiftUI

@main
struct TidyBarApp {
    @MainActor static func main() {
        if CommandLine.arguments.contains("--export-icon") {
            exportIcon()
            return
        }
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
        withExtendedLifetime(delegate) {}
    }

    @MainActor private static func exportIcon() {
        guard let index = CommandLine.arguments.firstIndex(of: "--export-icon"), CommandLine.arguments.count > index + 1 else { return }
        let url = URL(fileURLWithPath: CommandLine.arguments[index + 1])
        let image = CatArtwork.appIcon()
        guard let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }
        do { try png.write(to: url) }
        catch { fputs("Icon export failed: \(error)\n", stderr) }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var model: AppModel!
    private var statusBar: StatusBarController!
    private var shortcut: GlobalShortcut!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Avoid a second pair of menu items even when the executable is launched directly.
        let siblings = NSRunningApplication.runningApplications(withBundleIdentifier: "com.tidybar.app")
        if siblings.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            siblings.first(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier })?.activate()
            NSApp.terminate(nil)
            return
        }
        model = AppModel()
        statusBar = StatusBarController(model: model)
        statusBar.onOpenSettings = { [weak self] in self?.showSettings() }
        shortcut = GlobalShortcut()
        shortcut.onToggle = { [weak self] in self?.model.toggle() }
        model.shortcutAvailable = shortcut.register()
        NSApp.applicationIconImage = CatArtwork.appIcon()
        makeMainMenu()
        let firstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunched")
        let needsNativeSetup = model.usesNative && !UserDefaults.standard.bool(forKey: "nativeSetupV1")
        if firstLaunch || needsNativeSetup || CommandLine.arguments.contains("--settings") {
            showSettings()
        } else {
            model.setHidden(model.hideAtLaunch)
        }
        UserDefaults.standard.set(true, forKey: "hasLaunched")
        UserDefaults.standard.set(true, forKey: "nativeSetupV1")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    private func makeMainMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Tidy Bar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        NSApp.mainMenu = menu
    }

    @objc func showSettings() {
        guard model != nil else { return }
        if settingsWindow == nil {
            let view = SettingsView(model: model)
            let host = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: host)
            window.title = "Tidy Bar"
            window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isReleasedWhenClosed = false
            window.backgroundColor = NSColor(calibratedRed: 0.97, green: 0.96, blue: 0.93, alpha: 1)
            window.delegate = self
            window.setContentSize(host.view.fittingSize)
            window.center()
            settingsWindow = window
        }
        model.setSettingsOpen(true)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) { model.setSettingsOpen(false) }
    func windowDidMiniaturize(_ notification: Notification) { model.setSettingsOpen(false) }
    func windowDidDeminiaturize(_ notification: Notification) { model.setSettingsOpen(true) }
    func windowDidBecomeKey(_ notification: Notification) { model.refreshLoginStatus() }

    func applicationWillTerminate(_ notification: Notification) {
        shortcut?.unregister()
        statusBar?.tearDown()
    }
}
