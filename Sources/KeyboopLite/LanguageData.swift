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
                    let a = bytes[start + i]
                    let b = target[i]
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

/// Fixed 16-byte record:
/// UInt32 scalar #1, #2, #3, Float32 log probability, all little-endian.
/// The whole file is sorted lexicographically by the three scalars and memory-mapped.
final class MappedTrigramTable {
    private static let recordSize = 16
    private let data: Data
    private let recordCount: Int

    init(resource: String) {
        if let url = Bundle.main.url(forResource: resource, withExtension: "bin"),
           let mapped = try? Data(contentsOf: url, options: [.mappedIfSafe]),
           mapped.count % Self.recordSize == 0 {
            data = mapped
            recordCount = mapped.count / Self.recordSize
        } else {
            data = Data()
            recordCount = 0
        }
    }

    var isEmpty: Bool { recordCount == 0 }

    func value(_ a: UInt32, _ b: UInt32, _ c: UInt32) -> Float? {
        guard recordCount > 0 else { return nil }

        return data.withUnsafeBytes { raw -> Float? in
            let bytes = raw.bindMemory(to: UInt8.self)
            var low = 0
            var high = recordCount - 1

            @inline(__always)
            func u32(_ offset: Int) -> UInt32 {
                UInt32(bytes[offset])
                    | (UInt32(bytes[offset + 1]) << 8)
                    | (UInt32(bytes[offset + 2]) << 16)
                    | (UInt32(bytes[offset + 3]) << 24)
            }

            while low <= high {
                let mid = (low + high) / 2
                let offset = mid * Self.recordSize
                let x = u32(offset)
                let y = u32(offset + 4)
                let z = u32(offset + 8)

                let cmp: Int
                if x != a { cmp = x < a ? -1 : 1 }
                else if y != b { cmp = y < b ? -1 : 1 }
                else if z != c { cmp = z < c ? -1 : 1 }
                else {
                    let bits = u32(offset + 12)
                    return Float(bitPattern: bits)
                }

                if cmp < 0 { low = mid + 1 }
                else { high = mid - 1 }
            }
            return nil
        }
    }
}

final class LanguageData {
    static let shared = LanguageData()

    let wordsRu = MappedWordSet(resource: "words_ru")
    let wordsEn = MappedWordSet(resource: "words_en")
    private let triRu = MappedTrigramTable(resource: "trigrams_ru")
    private let triEn = MappedTrigramTable(resource: "trigrams_en")

    private init() {}

    var ready: Bool {
        !wordsRu.isEmpty && !wordsEn.isEmpty && !triRu.isEmpty && !triEn.isEmpty
    }

    func isWord(_ word: String, cyrillic: Bool) -> Bool {
        cyrillic ? wordsRu.contains(word) : wordsEn.contains(word)
    }

    func plausibility(_ word: String, cyrillic: Bool) -> Float {
        let table = cyrillic ? triRu : triEn
        let chars = Array(" " + word.lowercased() + " ")
        guard chars.count >= 3 else { return -.infinity }

        var scalars: [UInt32] = []
        scalars.reserveCapacity(chars.count)
        for ch in chars {
            let values = String(ch).unicodeScalars
            guard values.count == 1, let scalar = values.first else { return -20 }
            scalars.append(scalar.value)
        }

        var sum: Float = 0
        for i in 0...(scalars.count - 3) {
            sum += table.value(scalars[i], scalars[i + 1], scalars[i + 2]) ?? -20
        }
        return sum / Float(scalars.count - 2)
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

        let cyr = w.hasCyrillic
        let lat = w.hasLatin
        guard cyr != lat else { return .keep }

        let data = LanguageData.shared
        if ExceptionStore.shared.contains(w) { return .keep }
        if !cyr && techKeep.contains(w) { return .keep }
        if data.isWord(w, cyrillic: cyr) { return .keep }

        let toCyr = !cyr
        let swapped = Keymap.convert(raw, toCyrillic: toCyr).lowercased()
        guard swapped != w else { return .keep }

        if ExceptionStore.shared.forceContains(swapped) {
            return .convert(toCyrillic: toCyr)
        }

        if data.isWord(swapped, cyrillic: toCyr) {
            return .convert(toCyrillic: toCyr)
        }

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
