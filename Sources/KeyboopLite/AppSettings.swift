import Foundation
import CoreGraphics

final class AppSettings {
    static let shared = AppSettings()
    private let d = UserDefaults.standard

    private init() {
        d.register(defaults: [
            "autoEnabled": true,
            "autoSpace": true,
            "autoEnter": true,
            "autoTab": true,
            "snippetExpandSpace": true,
            "snippetExpandEnter": true,
            "snippetExpandTab": true,
            "plainPaste": false,
            "typoFix": true,
            "twoCapsFix": true,
            "caseChangeEnabled": false,
            "snippetPickEnabled": false
        ])
        importFromFullKeyboopOnce()
    }

    private func importFromFullKeyboopOnce() {
        guard !d.bool(forKey: "didImportFullKeyboop") else { return }
        defer { d.set(true, forKey: "didImportFullKeyboop") }
        guard let old = UserDefaults(suiteName: "ru.keyboop.app") else { return }

        let scalarKeys = [
            "autoEnabled", "snippetExpandSpace", "snippetExpandEnter", "snippetExpandTab",
            "plainPaste", "typoFix", "twoCapsFix"
        ]
        for key in scalarKeys {
            if let value = old.object(forKey: key) { d.set(value, forKey: key) }
        }
        for key in ["snippetsOrdered", "textSnippets", "ignoredWords", "forceSwapWords", "learnedWords"] {
            if let value = old.object(forKey: key) { d.set(value, forKey: key) }
        }
    }

    var autoEnabled: Bool {
        get { d.bool(forKey: "autoEnabled") }
        set { d.set(newValue, forKey: "autoEnabled") }
    }
    var autoSpace: Bool {
        get { d.bool(forKey: "autoSpace") }
        set { d.set(newValue, forKey: "autoSpace") }
    }
    var autoEnter: Bool {
        get { d.bool(forKey: "autoEnter") }
        set { d.set(newValue, forKey: "autoEnter") }
    }
    var autoTab: Bool {
        get { d.bool(forKey: "autoTab") }
        set { d.set(newValue, forKey: "autoTab") }
    }

    var snippetExpandSpace: Bool {
        get { d.bool(forKey: "snippetExpandSpace") }
        set { d.set(newValue, forKey: "snippetExpandSpace") }
    }
    var snippetExpandEnter: Bool {
        get { d.bool(forKey: "snippetExpandEnter") }
        set { d.set(newValue, forKey: "snippetExpandEnter") }
    }
    var snippetExpandTab: Bool {
        get { d.bool(forKey: "snippetExpandTab") }
        set { d.set(newValue, forKey: "snippetExpandTab") }
    }

    var plainPaste: Bool {
        get { d.bool(forKey: "plainPaste") }
        set { d.set(newValue, forKey: "plainPaste") }
    }
    var typoFix: Bool {
        get { d.bool(forKey: "typoFix") }
        set { d.set(newValue, forKey: "typoFix") }
    }
    var twoCapsFix: Bool {
        get { d.bool(forKey: "twoCapsFix") }
        set { d.set(newValue, forKey: "twoCapsFix") }
    }
    var caseChangeEnabled: Bool {
        get { d.bool(forKey: "caseChangeEnabled") }
        set { d.set(newValue, forKey: "caseChangeEnabled") }
    }
    var snippetPickEnabled: Bool {
        get { d.bool(forKey: "snippetPickEnabled") }
        set { d.set(newValue, forKey: "snippetPickEnabled") }
    }
}
