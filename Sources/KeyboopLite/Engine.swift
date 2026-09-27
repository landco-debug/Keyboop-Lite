import AppKit
import ApplicationServices

final class Engine {
    private let settings = AppSettings.shared
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var buffer = ""
    private var previousWord: String?
    private var snippetPickerArmed = false

    func start() -> Bool {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << CGEventType.tapDisabledByTimeout.rawValue)
            | CGEventMask(1 << CGEventType.tapDisabledByUserInput.rawValue)

        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, info in
                guard let info else { return Unmanaged.passUnretained(event) }
                let engine = Unmanaged<Engine>.fromOpaque(info).takeUnretainedValue()
                return engine.handle(type: type, event: event)
            },
            userInfo: userInfo
        ) else { return false }

        self.tap = tap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source { CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes) }
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        if event.getIntegerValueField(.eventSourceUserData) == TextTools.marker {
            return Unmanaged.passUnretained(event)
        }

        let key = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let relevant = flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift])

        if snippetPickerArmed {
            snippetPickerArmed = false
            if let digit = typedString(event).first, let n = Int(String(digit)), n >= 1, n <= 9 {
                let pairs = TextSnippetStore.shared.pairs
                if n <= pairs.count {
                    TextTools.postText(pairs[n - 1].1)
                    buffer.removeAll(keepingCapacity: true)
                    return nil
                }
            }
        }

        if settings.snippetPickEnabled, relevant == [.maskControl, .maskAlternate], key == 1 {
            snippetPickerArmed = true // Ctrl+Option+S, then 1…9
            return nil
        }

        if settings.caseChangeEnabled, relevant == [.maskControl, .maskAlternate], key == 32 {
            TextTools.toggleSelectedCase() // Ctrl+Option+U
            buffer.removeAll(keepingCapacity: true)
            return nil
        }

        if settings.plainPaste, relevant == [.maskCommand, .maskShift], key == 9 {
            TextTools.pastePlain()
            buffer.removeAll(keepingCapacity: true)
            return nil
        }

        if relevant.contains(.maskCommand) || relevant.contains(.maskControl) || relevant.contains(.maskAlternate) {
            buffer.removeAll(keepingCapacity: true)
            return Unmanaged.passUnretained(event)
        }

        if key == 51 {
            if !buffer.isEmpty { buffer.removeLast() }
            return Unmanaged.passUnretained(event)
        }

        if [123, 124, 125, 126, 115, 119].contains(key) {
            buffer.removeAll(keepingCapacity: true)
            return Unmanaged.passUnretained(event)
        }

        if key == 49 || key == 36 || key == 48 {
            let typed = buffer
            buffer.removeAll(keepingCapacity: true)
            guard !typed.isEmpty else { return Unmanaged.passUnretained(event) }

            let snippetBoundary = (key == 49 && settings.snippetExpandSpace)
                || (key == 36 && settings.snippetExpandEnter)
                || (key == 48 && settings.snippetExpandTab)
            let textBoundary = (key == 49 && settings.autoSpace)
                || (key == 36 && settings.autoEnter)
                || (key == 48 && settings.autoTab)

            if let result = transformed(typed, allowSnippet: snippetBoundary, allowTextFixes: textBoundary) {
                TextTools.replaceLastWord(deleteCount: typed.count, with: result.text, boundaryKey: key)
                if let toCyr = result.layoutDirection { KeyboardLayout.select(cyrillic: toCyr) }
                previousWord = result.text
                return nil
            }

            previousWord = typed
            return Unmanaged.passUnretained(event)
        }

        let text = typedString(event)
        if text.count == 1, let ch = text.first, !ch.isWhitespace {
            buffer.append(ch)
        } else if !text.isEmpty {
            buffer.removeAll(keepingCapacity: true)
        }
        return Unmanaged.passUnretained(event)
    }

    private struct Transform {
        let text: String
        let layoutDirection: Bool?
    }

    private func transformed(_ raw: String, allowSnippet: Bool, allowTextFixes: Bool) -> Transform? {
        let (core, suffix) = splitTrailingPunctuation(raw)
        guard !core.isEmpty else { return nil }

        if allowSnippet, let expansion = SnippetStore.shared.expansion(for: core) {
            return Transform(text: expansion + suffix, layoutDirection: nil)
        }

        guard allowTextFixes else { return nil }

        if settings.autoEnabled {
            switch LayoutDetectorLite.decide(word: core, previous: previousWord) {
            case .keep:
                break
            case .convert(let toCyr):
                let converted = Keymap.convert(core, toCyrillic: toCyr)
                return Transform(text: converted + suffix, layoutDirection: toCyr)
            }
        }

        if settings.typoFix, let fixed = TypoFix.shared.suggest(core) {
            return Transform(text: fixed + suffix, layoutDirection: nil)
        }

        if settings.twoCapsFix, let fixed = fixTwoLeadingCaps(core) {
            return Transform(text: fixed + suffix, layoutDirection: nil)
        }
        return nil
    }

    private func splitTrailingPunctuation(_ text: String) -> (String, String) {
        let punctuation = Set<Character>(".,!?;:…")
        var core = text
        var tail = ""
        while let last = core.last, punctuation.contains(last) {
            core.removeLast()
            tail.insert(last, at: tail.startIndex)
        }
        return (core, tail)
    }

    private func fixTwoLeadingCaps(_ word: String) -> String? {
        var chars = Array(word)
        guard chars.count >= 3,
              chars[0].isUppercase, chars[1].isUppercase, chars[2].isLowercase
        else { return nil }
        chars[1] = Character(String(chars[1]).lowercased())
        return String(chars)
    }

    private func typedString(_ event: CGEvent) -> String {
        var actual = 0
        var chars = [UniChar](repeating: 0, count: 8)
        event.keyboardGetUnicodeString(maxStringLength: chars.count, actualStringLength: &actual, unicodeString: &chars)
        guard actual > 0 else { return "" }
        return String(utf16CodeUnits: chars, count: actual)
    }
}
