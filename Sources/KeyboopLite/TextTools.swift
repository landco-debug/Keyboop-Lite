import AppKit
import Carbon

enum TextTools {
    static let marker: Int64 = 0x4B424C54

    static func postText(_ text: String) {
        guard !text.isEmpty else { return }
        let source = CGEventSource(stateID: .combinedSessionState)
        let utf16 = Array(text.utf16)

        let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        down?.setIntegerValueField(.eventSourceUserData, value: marker)
        utf16.withUnsafeBufferPointer { buffer in
            down?.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
        }
        down?.post(tap: .cghidEventTap)

        let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        up?.setIntegerValueField(.eventSourceUserData, value: marker)
        up?.post(tap: .cghidEventTap)
    }

    static func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        down?.setIntegerValueField(.eventSourceUserData, value: marker)
        down?.post(tap: .cghidEventTap)

        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        up?.setIntegerValueField(.eventSourceUserData, value: marker)
        up?.post(tap: .cghidEventTap)
    }

    static func replaceLastWord(deleteCount: Int, with replacement: String, boundaryKey: CGKeyCode) {
        for _ in 0..<deleteCount { postKey(51) }
        postText(replacement)
        postKey(boundaryKey)
    }

    static func pastePlain() {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else { return }
        postText(text)
    }

    static func toggleSelectedCase() {
        let pb = NSPasteboard.general
        let snapshot: [[(NSPasteboard.PasteboardType, Data)]] = (pb.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        }

        postKey(8, flags: .maskCommand)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            guard let selected = pb.string(forType: .string), !selected.isEmpty, selected.count <= 5000 else {
                restore(snapshot, to: pb)
                return
            }

            let letters = selected.filter { $0.isLetter }
            let isUpper = !letters.isEmpty && letters.allSatisfy { $0.isUppercase }
            let changed = isUpper ? selected.lowercased() : selected.uppercased()

            pb.clearContents()
            pb.setString(changed, forType: .string)
            postKey(9, flags: .maskCommand)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                restore(snapshot, to: pb)
            }
        }
    }

    private static func restore(_ snapshot: [[(NSPasteboard.PasteboardType, Data)]], to pb: NSPasteboard) {
        pb.clearContents()
        let items: [NSPasteboardItem] = snapshot.map { record in
            let item = NSPasteboardItem()
            for (type, data) in record { item.setData(data, forType: type) }
            return item
        }
        if !items.isEmpty { pb.writeObjects(items) }
    }
}

enum KeyboardLayout {
    private static var russian: TISInputSource?
    private static var latin: TISInputSource?

    static func select(cyrillic: Bool) {
        if russian == nil || latin == nil { discover() }
        if let source = cyrillic ? russian : latin {
            TISSelectInputSource(source)
        }
    }

    private static func discover() {
        let list = TISCreateInputSourceList(nil, false).takeRetainedValue()
        let count = CFArrayGetCount(list)

        for index in 0..<count {
            let rawSource = CFArrayGetValueAtIndex(list, index)
            let source = unsafeBitCast(rawSource, to: TISInputSource.self)

            guard let langsPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else {
                continue
            }

            let langs = unsafeBitCast(langsPtr, to: CFArray.self)
            let langCount = CFArrayGetCount(langs)
            var values: [String] = []
            values.reserveCapacity(langCount)

            for langIndex in 0..<langCount {
                let rawLang = CFArrayGetValueAtIndex(langs, langIndex)
                let cfLang = unsafeBitCast(rawLang, to: CFString.self)
                values.append((cfLang as String).lowercased())
            }

            if russian == nil, values.contains(where: { $0.hasPrefix("ru") }) {
                russian = source
            }
            if latin == nil, values.contains(where: { $0.hasPrefix("en") }) {
                latin = source
            }
        }
    }
}
