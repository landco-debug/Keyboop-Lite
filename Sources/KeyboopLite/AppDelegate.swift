import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let engine = Engine()
    private var statusItem: NSStatusItem!
    private var settingsWC: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = LanguageData.shared.ready
        _ = TypoFix.shared

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboop Lite")
        }
        rebuildMenu()

        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }

        if !engine.start() {
            showSettings()
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let auto = NSMenuItem(title: "Автопереключение", action: #selector(toggleAuto(_:)), keyEquivalent: "")
        auto.target = self
        auto.state = AppSettings.shared.autoEnabled ? .on : .off
        menu.addItem(auto)
        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Настройки…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let quit = NSMenuItem(title: "Выйти из Keyboop Lite", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    @objc private func toggleAuto(_ sender: NSMenuItem) {
        AppSettings.shared.autoEnabled.toggle()
        sender.state = AppSettings.shared.autoEnabled ? .on : .off
    }

    @objc private func showSettings() {
        if settingsWC == nil { settingsWC = SettingsWindowController() }
        NSApp.activate(ignoringOtherApps: true)
        settingsWC?.showWindow(nil)
        settingsWC?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
