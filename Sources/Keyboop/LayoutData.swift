import Foundation

#if KEYBOOP_LITE
/// Read-only exact word membership for Lite.
///
/// The full Keyboop build historically decodes words_ru/en.json into Set<String>. That is fast but
/// expensive in a tiny resident agent: 220k+ Swift String objects plus hash-table buckets stay in
/// heap memory for the whole session. Lite instead memory-maps a build-generated, sorted UTF-8 file
/// and keeps only 32-bit line offsets (~0.9 MB for both dictionaries). Membership is still exact;
/// no Bloom filter, truncation, stemming or probabilistic lookup is involved.
///
/// ExtraWords stays as the same small in-process Set overlay, so all product-specific vocabulary has
/// exactly the same precedence as before. If a .lex resource is ever missing, Lite falls back to the
/// original JSON -> Set path rather than silently degrading switching quality.
final class CompactWordSet {
    private enum Base {
        case mapped(Data, [Int32], Int)   // bytes, line starts, payload end (excludes final newline)
        case fallback(Set<String>)
    }

    private let base: Base
    private let overlay: Set<String>
    private(set) var count: Int = 0
    var isEmpty: Bool { count == 0 }

    init(mappedURL: URL?, fallback: Set<String>, overlay: Set<String>) {
        if let url = mappedURL,
           let mapped = try? Data(contentsOf: url, options: [.mappedIfSafe]),
           !mapped.isEmpty {
            let payloadEnd = mapped.last == 0x0A ? mapped.count - 1 : mapped.count
            var starts: [Int32] = []
            if payloadEnd > 0 {
                starts.reserveCapacity(max(1, payloadEnd / 12))
                starts.append(0)
                mapped.withUnsafeBytes { raw in
                    let bytes = raw.bindMemory(to: UInt8.self)
                    if payloadEnd > 1 {
                        for i in 0..<(payloadEnd - 1) where bytes[i] == 0x0A {
                            starts.append(Int32(i + 1))
                        }
                    }
                }
            }
            base = .mapped(mapped, starts, payloadEnd)
        } else {
            base = .fallback(fallback)
        }
        self.overlay = overlay

        let baseCount: Int
        switch base {
        case .mapped(_, let starts, _): baseCount = starts.count
        case .fallback(let set): baseCount = set.count
        }
        var overlayOnly = 0
        for word in overlay where !baseContains(word) { overlayOnly += 1 }
        count = baseCount + overlayOnly
    }

    func contains(_ word: String) -> Bool {
        overlay.contains(word) || baseContains(word)
    }

    private func baseContains(_ word: String) -> Bool {
        switch base {
        case .fallback(let set):
            return set.contains(word)
        case .mapped(let data, let starts, let payloadEnd):
            guard !starts.isEmpty else { return false }

            if let result = word.utf8.withContiguousStorageIfAvailable({ query -> Bool in
                data.withUnsafeBytes { raw -> Bool in
                    let bytes = raw.bindMemory(to: UInt8.self)
                    return Self.binaryContains(query, in: bytes, starts: starts, payloadEnd: payloadEnd)
                }
            }) {
                return result
            }

            // Unusual non-contiguous String backing. Keep exact semantics with a tiny temporary query
            // buffer rather than imposing an ASCII-only assumption.
            let query = Array(word.utf8)
            return query.withUnsafeBufferPointer { q in
                data.withUnsafeBytes { raw -> Bool in
                    let bytes = raw.bindMemory(to: UInt8.self)
                    return Self.binaryContains(q, in: bytes, starts: starts, payloadEnd: payloadEnd)
                }
            }
        }
    }

    private static func binaryContains(_ query: UnsafeBufferPointer<UInt8>,
                                       in bytes: UnsafeBufferPointer<UInt8>,
                                       starts: [Int32],
                                       payloadEnd: Int) -> Bool {
        var lo = 0
        var hi = starts.count
        while lo < hi {
            let mid = lo + (hi - lo) / 2
            let start = Int(starts[mid])
            let end = mid + 1 < starts.count ? Int(starts[mid + 1]) - 1 : payloadEnd
            let cmp = compare(query, bytes: bytes, start: start, end: end)
            if cmp == 0 { return true }
            if cmp < 0 { hi = mid }
            else { lo = mid + 1 }
        }
        return false
    }

    /// -1 when query < stored line, 0 when equal, +1 when query > stored line.
    private static func compare(_ query: UnsafeBufferPointer<UInt8>,
                                bytes: UnsafeBufferPointer<UInt8>,
                                start: Int,
                                end: Int) -> Int {
        let lineCount = max(0, end - start)
        let n = min(query.count, lineCount)
        if n > 0 {
            for i in 0..<n {
                let q = query[i]
                let b = bytes[start + i]
                if q < b { return -1 }
                if q > b { return 1 }
            }
        }
        if query.count == lineCount { return 0 }
        return query.count < lineCount ? -1 : 1
    }
}
#endif

/// Языковые данные для детекции: триграммные лог-вероятности + словари RU/EN.
/// Источник данных — keyswitcher (MIT, © 2026 Ilya Granin), см. THIRD_PARTY.md.
final class LayoutData {
    static let shared = LayoutData()

    let trigramsRu: [String: Double]
    let trigramsEn: [String: Double]
#if KEYBOOP_LITE
    let wordsRu: CompactWordSet
    let wordsEn: CompactWordSet
#else
    let wordsRu: Set<String>
    let wordsEn: Set<String>
#endif
    let isLoaded: Bool

    private init() {
        trigramsRu = Self.loadDict("trigrams_ru")
        trigramsEn = Self.loadDict("trigrams_en")
#if KEYBOOP_LITE
        var ruOverlay = ExtraWords.ru
        ruOverlay.formUnion(ExtraWords.ruDev)
        ruOverlay.formUnion(ExtraWords.ruAbbr)
        ruOverlay.formUnion(ExtraWords.ruShort)
        ruOverlay.formUnion(ExtraWords.ruCommonForms)
        ruOverlay.formUnion(ExtraWords.ruLoanNames)

        wordsRu = Self.loadCompactSet("words_ru", overlay: ruOverlay)
        wordsEn = Self.loadCompactSet("words_en", overlay: ExtraWords.en)
#else
        wordsRu = Self.loadSet("words_ru").union(ExtraWords.ru).union(ExtraWords.ruDev).union(ExtraWords.ruAbbr).union(ExtraWords.ruShort).union(ExtraWords.ruCommonForms).union(ExtraWords.ruLoanNames)
        wordsEn = Self.loadSet("words_en").union(ExtraWords.en)
#endif
        isLoaded = !trigramsRu.isEmpty && !wordsEn.isEmpty
        NSLog("Keyboop: LayoutData loaded=\(isLoaded) ru-tri=\(trigramsRu.count) en-tri=\(trigramsEn.count) ru-w=\(wordsRu.count) en-w=\(wordsEn.count)")
    }

    /// Средняя лог-вероятность триграмм слова (с паддингом пробелами). Штраф −20 за отсутствие.
    func plausibility(_ word: String, cyrillic: Bool) -> Double {
        let table = cyrillic ? trigramsRu : trigramsEn
        let chars = Array(" " + word.lowercased() + " ")
        guard chars.count >= 3 else { return -.infinity }
        var sum = 0.0
        for i in 0...(chars.count - 3) {
            sum += table[String(chars[i..<(i + 3)])] ?? -20.0
        }
        return sum / Double(chars.count - 2)
    }

    /// URL данных: из bundle (приложение) или из KEYBOOP_DATA_DIR (CLI-инструменты).
    private static func dataURL(_ name: String, extension ext: String = "json") -> URL? {
        if let dir = ProcessInfo.processInfo.environment["KEYBOOP_DATA_DIR"], !dir.isEmpty {
            let u = URL(fileURLWithPath: dir).appendingPathComponent("\(name).\(ext)")
            if FileManager.default.fileExists(atPath: u.path) { return u }
        }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    private static func loadDict(_ name: String) -> [String: Double] {
        guard let url = dataURL(name),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: Double].self, from: data) else {
            NSLog("Keyboop: failed to load \(name).json")
            return [:]
        }
        return dict
    }

    private static func loadSet(_ name: String) -> Set<String> {
        guard let url = dataURL(name),
              let data = try? Data(contentsOf: url),
              let arr = try? JSONDecoder().decode([String].self, from: data) else {
            NSLog("Keyboop: failed to load \(name).json")
            return []
        }
        return Set(arr)
    }

#if KEYBOOP_LITE
    private static func loadCompactSet(_ name: String, overlay: Set<String>) -> CompactWordSet {
        let lexURL = dataURL(name, extension: "lex")
        // Keep the old loader solely as a fail-safe. In the normal Lite artifact .lex always exists,
        // so the large JSON arrays are never decoded into resident String hash tables.
        let fallback: Set<String> = lexURL == nil ? loadSet(name) : []
        let result = CompactWordSet(mappedURL: lexURL, fallback: fallback, overlay: overlay)
        if lexURL == nil {
            NSLog("Keyboop: compact lexicon \(name).lex missing; using exact JSON Set fallback")
        }
        return result
    }
#endif
}
