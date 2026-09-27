import AppKit
import ServiceManagement

final class SettingsWindowController: NSWindowController {
    init() {
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        tabs.addTabViewItem(NSTabViewItem(viewController: SwitchingVC()))
        tabs.tabViewItems[0].label = "Переключение"
        tabs.addTabViewItem(NSTabViewItem(viewController: ExceptionsVC()))
        tabs.tabViewItems[1].label = "Исключения"
        tabs.addTabViewItem(NSTabViewItem(viewController: AutoreplaceVC()))
        tabs.tabViewItems[2].label = "Автозамена"
        tabs.addTabViewItem(NSTabViewItem(viewController: GeneralVC()))
        tabs.tabViewItems[3].label = "Общие"

        let window = NSWindow(contentViewController: tabs)
        window.title = "Keyboop Lite"
        window.setContentSize(NSSize(width: 760, height: 560))
        window.styleMask.insert([.titled, .closable, .miniaturizable])
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }
}

private func checkbox(_ title: String, value: Bool, action: @escaping (Bool) -> Void) -> NSButton {
    let b = NSButton(checkboxWithTitle: title, target: nil, action: nil)
    b.state = value ? .on : .off
    final class Box: NSObject {
        let action: (Bool) -> Void
        init(_ action: @escaping (Bool) -> Void) { self.action = action }
        @objc func fire(_ sender: NSButton) { action(sender.state == .on) }
    }
    let box = Box(action)
    b.target = box
    b.action = #selector(Box.fire(_:))
    objc_setAssociatedObject(b, Unmanaged.passUnretained(b).toOpaque(), box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return b
}

private class StackVC: NSViewController {
    let stack = NSStackView()
    override func loadView() {
        view = NSView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 28)
        ])
    }
    func title(_ text: String) {
        let l = NSTextField(labelWithString: text)
        l.font = .boldSystemFont(ofSize: 22)
        stack.addArrangedSubview(l)
    }
    func note(_ text: String) {
        let l = NSTextField(wrappingLabelWithString: text)
        l.textColor = .secondaryLabelColor
        stack.addArrangedSubview(l)
    }
}

private final class SwitchingVC: StackVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        let s = AppSettings.shared
        title("Переключение")
        note("Автоматически исправляет слово, набранное в неверной RU/EN раскладке.")
        stack.addArrangedSubview(checkbox("Автопереключение", value: s.autoEnabled) { s.autoEnabled = $0 })
        stack.addArrangedSubview(checkbox("Срабатывать по пробелу", value: s.autoSpace) { s.autoSpace = $0 })
        stack.addArrangedSubview(checkbox("Срабатывать по Enter", value: s.autoEnter) { s.autoEnter = $0 })
        stack.addArrangedSubview(checkbox("Срабатывать по Tab", value: s.autoTab) { s.autoTab = $0 })
    }
}

private final class ExceptionsVC: StackVC {
    private let editor = NSTextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title("Исключения")
        note("Одно слово на строку. Эти слова автоматическое переключение не трогает.")
        editor.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        editor.string = ExceptionStore.shared.ignored.sorted().joined(separator: "\n")
        let scroll = NSScrollView()
        scroll.documentView = editor
        scroll.hasVerticalScroller = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.widthAnchor.constraint(equalToConstant: 650).isActive = true
        scroll.heightAnchor.constraint(equalToConstant: 330).isActive = true
        stack.addArrangedSubview(scroll)
        let save = NSButton(title: "Сохранить", target: self, action: #selector(saveNow))
        stack.addArrangedSubview(save)
    }

    @objc private func saveNow() {
        ExceptionStore.shared.setIgnored(editor.string.components(separatedBy: .newlines))
    }
}

private final class AutoreplaceVC: StackVC {
    private let replacements = NSTextView()
    private let snippets = NSTextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        let s = AppSettings.shared
        title("Автозамена")
        note("Формат списка: сокращение = текст замены. Регистр и RU/EN раскладка сокращения не учитываются.")

        replacements.font = .systemFont(ofSize: 13)
        replacements.string = SnippetStore.shared.pairs.map { "\($0.0) = \($0.1)" }.joined(separator: "\n")
        stack.addArrangedSubview(scroll(replacements, height: 120))

        let row = NSStackView(views: [
            checkbox("Пробел", value: s.snippetExpandSpace) { s.snippetExpandSpace = $0 },
            checkbox("Enter", value: s.snippetExpandEnter) { s.snippetExpandEnter = $0 },
            checkbox("Tab", value: s.snippetExpandTab) { s.snippetExpandTab = $0 }
        ])
        row.orientation = .horizontal
        row.spacing = 14
        stack.addArrangedSubview(row)

        stack.addArrangedSubview(checkbox("Вставлять без форматирования (⇧⌘V)", value: s.plainPaste) { s.plainPaste = $0 }))
        stack.addArrangedSubview(checkbox("Исправлять опечатки", value: s.typoFix) { s.typoFix = $0 }))
        stack.addArrangedSubview(checkbox("Две заглавные подряд", value: s.twoCapsFix) { s.twoCapsFix = $0 }))
        stack.addArrangedSubview(checkbox("Менять регистр выделенного (⌃⌥U)", value: s.caseChangeEnabled) { s.caseChangeEnabled = $0 }))

        note("Сниппеты для осознанной вставки: название = текст. Если включено, нажмите ⌃⌥S, затем цифру 1–9.")
        snippets.font = .systemFont(ofSize: 13)
        snippets.string = TextSnippetStore.shared.pairs.map { "\($0.0) = \($0.1)" }.joined(separator: "\n")
        stack.addArrangedSubview(scroll(snippets, height: 90))
        stack.addArrangedSubview(checkbox("Вставлять сниппет по сочетанию", value: s.snippetPickEnabled) { s.snippetPickEnabled = $0 }))

        let save = NSButton(title: "Сохранить списки", target: self, action: #selector(saveNow))
        stack.addArrangedSubview(save)
    }

    private func scroll(_ text: NSTextView, height: CGFloat) -> NSScrollView {
        let v = NSScrollView()
        v.documentView = text
        v.hasVerticalScroller = true
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: 650).isActive = true
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }

    @objc private func saveNow() {
        SnippetStore.shared.setPairs(parse(replacements.string))
        TextSnippetStore.shared.setPairs(parse(snippets.string))
    }

    private func parse(_ text: String) -> [(String, String)] {
        text.components(separatedBy: .newlines).compactMap { line in
            guard let r = line.range(of: "=") else { return nil }
            let a = line[..<r.lowerBound].trimmingCharacters(in: .whitespaces)
            let b = line[r.upperBound...].trimmingCharacters(in: .whitespaces)
            return a.isEmpty ? nil : (a, b)
        }
    }
}

private final class GeneralVC: StackVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        title("Общие")
        note("Lite не содержит Whisper, Parakeet, FluidAudio, Translation, Sparkle и постоянного наблюдателя буфера.")

        let access = NSButton(title: "Запросить доступ Accessibility…", target: self, action: #selector(requestAX))
        stack.addArrangedSubview(access)

        if #available(macOS 13.0, *) {
            let enabled = SMAppService.mainApp.status == .enabled
            stack.addArrangedSubview(checkbox("Запускать при входе в систему", value: enabled) { on in
                do {
                    if on { try SMAppService.mainApp.register() }
                    else { try SMAppService.mainApp.unregister() }
                } catch {
                    NSSound.beep()
                }
            }))
        }
    }

    @objc private func requestAX() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
