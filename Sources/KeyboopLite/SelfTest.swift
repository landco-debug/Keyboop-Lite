import Foundation

enum SelfTest {
    static func run() -> Int32 {
        var failures: [String] = []

        func expect(_ condition: @autoclosure () -> Bool, _ name: String) {
            if !condition() { failures.append(name) }
        }

        expect(LanguageData.shared.ready, "language resources load")
        expect(Keymap.convert("ghbdtn", toCyrillic: true) == "привет", "EN→RU key map")
        expect(Keymap.convert("привет", toCyrillic: false) == "ghbdtn", "RU→EN key map")
        expect(Keymap.canonical("ЕУЫЕ") == "test", "canonical autoreplace trigger")
        expect(LanguageData.shared.isWord("привет", cyrillic: true), "RU dictionary membership")
        expect(LanguageData.shared.isWord("hello", cyrillic: false), "EN dictionary membership")

        switch LayoutDetectorLite.decide(word: "ghbdtn", previous: nil) {
        case .convert(let toCyrillic):
            expect(toCyrillic, "detector ghbdtn→RU direction")
        case .keep:
            failures.append("detector ghbdtn converts")
        }

        expect(TypoFix.shared.suggest("тедефон") == "телефон", "typo table")

        if failures.isEmpty {
            print("SELFTEST OK")
            return 0
        }

        for failure in failures {
            fputs("SELFTEST FAIL: \(failure)\n", stderr)
        }
        return 1
    }
}
