import Foundation

final class MappedWordSet {
    private let data: Data
    private var offsets: [UInt32] = []

    init(resource: String) {
        if let url = Bundle.main.url(forResource: resource, withExtension: "txt"),
           let mapped = try? Data(contentsOf: url, options: [.mappedIfSafe]) {
            data = mapped
        } else {
            data = Data()
        }
        offsets.reserveCapacity(max(1, data.count / 14))
        if !data.isEmpty {
            offsets.append(0)
            data.withUnsafeBytes { raw in
                let bytes = raw.bindMemory(to: UInt8.self)
                for i in 0..<bytes.count where bytes[i] == 10 && i + 1 < bytes.count {
                    offsets.append(UInt32(i + 1))
                }
            }
        }
    }

    var isEmpty: Bool { offsets.isEmpty }

    func contains(_ word: String) -> Bool {
        guard !offsets.isEmpty else { return false }
        let target = Array(word.lowercased().utf8)
        var low = 0
        var high = offsets.count - 1
        while low <= high {
            let mid = (low + high) / 2
            let cmp = compareLine(mid, to: target)
            if cmp == 0 { return true }
            if cmp < 0 { low = mid + 1 } else { high = mid - 1 }
        }
        return false
    }

    private func compareLine(_ index: Int, to target: [UInt8]) -> Int {
        let start = Int(offsets[index])
        let end: Int
        if index + 1 < offsets.count {
            end = Int(offsets[index + 1]) - 1
        } else {
            end = data.last == 10 ? data.count - 1 : data.count
        }

        return data.withUnsafeBytes { raw -> Int in
            let bytes = raw.bindMemory(to: UInt8.self)
            let n = min(end - start, target.count)
            if n > 0 {
                for i in 0..<n {
                    let a = bytes[start + i], b = target[i]
                    if a < b { return -1 }
                    if a > b { return 1 }
                }
            }
            let lineCount = end - start
            if lineCount < target.count { return -1 }
            if lineCount > target.count { return 1 }
            return 0
        }
    }
}

final class LanguageData {
    static let shared = LanguageData()

    let wordsRu = MappedWordSet(resource: "words_ru")
    let wordsEn = MappedWordSet(resource: "words_en")
    private let triRu: [String: Float]
    private let triEn: [String: Float]

    private init() {
        triRu = Self.loadTrigrams("trigrams_ru")
        triEn = Self.loadTrigrams("trigrams_en")
    }

    var ready: Bool { !wordsRu.isEmpty && !wordsEn.isEmpty && !triRu.isEmpty && !triEn.isEmpty }

    func isWord(_ word: String, cyrillic: Bool) -> Bool {
        cyrillic ? wordsRu.contains(word) : wordsEn.contains(word)
    }

    func plausibility(_ word: String, cyrillic: Bool) -> Float {
        let table = cyrillic ? triRu : triEn
        let chars = Array(" " + word.lowercased() + " ")
        guard chars.count >= 3 else { return -.infinity }
        var sum: Float = 0
        for i in 0...(chars.count - 3) {
            sum += table[String(chars[i..<(i + 3)])] ?? -20
        }
        return sum / Float(chars.count - 2)
    }

    private static func loadTrigrams(_ name: String) -> [String: Float] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode([String: Double].self, from: data)
        else { return [:] }
        var out: [String: Float] = [:]
        out.reserveCapacity(raw.count)
        for (k, v) in raw { out[k] = Float(v) }
        return out
    }
}

enum LayoutDecision {
    case keep
    case convert(toCyrillic: Bool)
}

enum LayoutDetectorLite {
    static let margin: Float = 2.0
    private static let ruSingle: Set<String> = ["а","в","и","к","о","с","у","я"]
    private static let techKeep: Set<String> = [
        "http","https","url","api","json","xml","yaml","csv","html","css","sdk","cli","gui",
        "ssh","ftp","tcp","udp","ip","dns","vpn","ssl","tls","sql","git","npm","cpu","gpu",
        "ram","ssd","usb","pdf","png","jpg","svg","llm","gpt","ai","ui","ux","macos","ios"
    ]

    static func decide(word raw: String, previous: String?) -> LayoutDecision {
        let w = raw.lowercased()
        guard !w.isEmpty else { return .keep }
        let cyr = w.hasCyrillic, lat = w.hasLatin
        guard cyr != lat else { return .keep }

        let data = LanguageData.shared
        if ExceptionStore.shared.contains(w) { return .keep }
        if !cyr && techKeep.contains(w) { return .keep }
        if data.isWord(w, cyrillic: cyr) { return .keep }

        let toCyr = !cyr
        let swapped = Keymap.convert(raw, toCyrillic: toCyr).lowercased()
        guard swapped != w else { return .keep }

        if ExceptionStore.shared.forceContains(swapped) { return .convert(toCyrillic: toCyr) }
        if data.isWord(swapped, cyrillic: toCyr) { return .convert(toCyrillic: toCyr) }

        if w.count == 1 {
            if !cyr, ruSingle.contains(swapped), previous?.hasCyrillic == true {
                return .convert(toCyrillic: true)
            }
            return .keep
        }

        guard w.count >= 3 else { return .keep }
        let orig = data.plausibility(w, cyrillic: cyr)
        let alt = data.plausibility(swapped, cyrillic: toCyr)
        return alt > orig + margin ? .convert(toCyrillic: toCyr) : .keep
    }
}
