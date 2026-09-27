import Foundation

enum Keymap {
    private static let pairs: [(Character, Character)] = [
        ("\u{0060}","ё"),("q","й"),("w","ц"),("e","у"),("r","к"),("t","е"),("y","н"),("u","г"),
        ("i","ш"),("o","щ"),("p","з"),("[","х"),("]","ъ"),
        ("a","ф"),("s","ы"),("d","в"),("f","а"),("g","п"),("h","р"),("j","о"),("k","л"),
        ("l","д"),(";","ж"),("'","э"),("z","я"),("x","ч"),("c","с"),("v","м"),("b","и"),
        ("n","т"),("m","ь"),(",","б"),(".","ю"),("/",".")
    ]

    static let enToRu: [Character: Character] = {
        var out: [Character: Character] = [:]
        for (e, r) in pairs {
            out[e] = r
            if e.isLetter { out[Character(String(e).uppercased())] = Character(String(r).uppercased()) }
        }
        return out
    }()

    static let ruToEn: [Character: Character] = {
        var out: [Character: Character] = [:]
        for (e, r) in pairs {
            out[r] = e
            if e.isLetter { out[Character(String(r).uppercased())] = Character(String(e).uppercased()) }
        }
        return out
    }()

    static func convert(_ text: String, toCyrillic: Bool) -> String {
        let map = toCyrillic ? enToRu : ruToEn
        return String(text.map { map[$0] ?? $0 })
    }

    static func canonical(_ text: String) -> String {
        convert(text, toCyrillic: false).lowercased()
    }
}

extension String {
    var hasCyrillic: Bool {
        unicodeScalars.contains { (0x0400...0x052F).contains(Int($0.value)) }
    }
    var hasLatin: Bool {
        unicodeScalars.contains {
            (0x0041...0x005A).contains(Int($0.value)) || (0x0061...0x007A).contains(Int($0.value))
        }
    }
}
