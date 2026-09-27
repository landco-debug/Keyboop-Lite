import Foundation

final class ExceptionStore {
    static let shared = ExceptionStore()
    private let d = UserDefaults.standard
    private(set) var ignored: Set<String> = []
    private(set) var learned: Set<String> = []
    private(set) var force: Set<String> = []

    private init() { reload() }

    func reload() {
        ignored = Set((d.array(forKey: "ignoredWords") as? [String] ?? []).map { $0.lowercased() })
        learned = Set((d.array(forKey: "learnedWords") as? [String] ?? []).map { $0.lowercased() })
        force = Set((d.array(forKey: "forceSwapWords") as? [String] ?? []).map { $0.lowercased() })
    }

    func contains(_ word: String) -> Bool {
        let w = word.lowercased()
        return ignored.contains(w) || learned.contains(w)
    }

    func forceContains(_ word: String) -> Bool {
        force.contains(word.lowercased())
    }

    func setIgnored(_ words: [String]) {
        ignored = Set(
            words
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
        d.set(Array(ignored).sorted(), forKey: "ignoredWords")
    }
}

final class SnippetStore {
    static let shared = SnippetStore()
    private let d = UserDefaults.standard
    private let key = "snippetsOrdered"
    private(set) var pairs: [(String, String)] = []
    private var index: [String: String] = [:]

    private init() { reload() }

    func reload() {
        pairs = (d.array(forKey: key) as? [[String]] ?? []).compactMap {
            $0.count >= 2 ? ($0[0], $0[1]) : nil
        }
        rebuild()
    }

    func setPairs(_ value: [(String, String)]) {
        pairs = value.filter { !$0.0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        d.set(pairs.map { [$0.0, $0.1] }, forKey: key)
        rebuild()
    }

    func expansion(for word: String) -> String? {
        index[Keymap.canonical(word)]
    }

    private func rebuild() {
        index.removeAll(keepingCapacity: true)
        for (trigger, expansion) in pairs {
            let canonical = Keymap.canonical(trigger)
            if !canonical.isEmpty { index[canonical] = expansion }
        }
    }
}

final class TextSnippetStore {
    static let shared = TextSnippetStore()
    private let d = UserDefaults.standard
    private let key = "textSnippets"
    private(set) var pairs: [(String, String)] = []

    private init() { reload() }

    func reload() {
        pairs = (d.array(forKey: key) as? [[String]] ?? []).compactMap {
            $0.count >= 2 ? ($0[0], $0[1]) : nil
        }
    }

    func setPairs(_ value: [(String, String)]) {
        pairs = value.filter { !$0.0.isEmpty || !$0.1.isEmpty }
        d.set(pairs.map { [$0.0, $0.1] }, forKey: key)
    }
}

final class TypoFix {
    static let shared = TypoFix()
    private var ru: [String: String] = [:]
    private var en: [String: String] = [:]

    private init() {
        guard let url = Bundle.main.url(forResource: "typo_rules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let all = try? JSONDecoder().decode([String: [String: String]].self, from: data)
        else { return }

        ru = all["ru"] ?? [:]
        en = all["en"] ?? [:]
    }

    func suggest(_ word: String) -> String? {
        let lower = word.lowercased()
        let isRu = lower.hasCyrillic
        let isEn = lower.hasLatin
        guard isRu != isEn else { return nil }
        if LanguageData.shared.isWord(lower, cyrillic: isRu) { return nil }

        if let fixed = (isRu ? ru : en)[lower] {
            return matchCase(fixed, like: word)
        }

        var candidates = Set<String>()
        let chars = Array(lower)

        if chars.count >= 3 {
            for i in 0..<(chars.count - 1) {
                var variant = chars
                variant.swapAt(i, i + 1)
                let candidate = String(variant)
                if LanguageData.shared.isWord(candidate, cyrillic: isRu) {
                    candidates.insert(candidate)
                }
            }

            for i in 0..<(chars.count - 1) where chars[i] == chars[i + 1] {
                var variant = chars
                variant.remove(at: i)
                let candidate = String(variant)
                if LanguageData.shared.isWord(candidate, cyrillic: isRu) {
                    candidates.insert(candidate)
                }
            }
        }

        guard candidates.count == 1, let only = candidates.first else { return nil }
        return matchCase(only, like: word)
    }

    private func matchCase(_ fixed: String, like source: String) -> String {
        if source.allSatisfy({ !$0.isLetter || $0.isUppercase }) {
            return fixed.uppercased()
        }

        if source.first?.isUppercase == true {
            return fixed.prefix(1).uppercased() + String(fixed.dropFirst())
        }

        return fixed
    }
}
