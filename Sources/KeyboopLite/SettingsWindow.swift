import AppKit
import ApplicationServices
import ServiceManagement

private final class ClosureCheckbox: NSButton {
    var onChange: ((Bool) -> Void)?

    convenience init(_ title: String, value: Bool, onChange: @escaping (Bool) -> Void) {
        self.init(checkboxWithTitle: title, target: nil, action: nil)
        self.state = value ? .on : .off
        self.onChange = onChange
        self.target = self
        self.action = #selector(fire)
    }

    @objc private func fire() {
        onChange?(state == .on)
    }
}

private func checkbox(_ title: String, value: Bool, action: @escaping (Bool) -> Void) -> NSButton {
    ClosureCheckbox(title, value: value, onChange: action)
}

final class SettingsWindowController: NSWindowController {
    init() {
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar

        let switching = NSTabViewItem(viewController: SwitchingVC())
        switching.label = "Переключение"
        tabs.addTabViewItem(switching)

        let exceptions = NSTabViewItem(viewController: ExceptionsVC())
        exceptions.label = "Исключения"
        tabs.addTabViewItem(exceptions)

        let autoreplace = NSTabViewItem(viewController: AutoreplaceVC())
        autoreplace.label = "Автозамена"
        tabs.addTabViewItem(autoreplace)

        let general = NSTabViewItem(viewController: GeneralVC())
        general.label = "Общие"
        tabs.addTabViewItem(general)

        let window = NSWindow(contentViewController: tabs)
        window.title = "Keyboop Lite"
        window.setContentSize(NSSize(width: 760, height: 560))
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }
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

    func addTitle(_ text: String) {
        let label = NSTextField(labelWithString: text)
        label.font = .boldSystemFont(ofSize: 22)
        stack.addArrangedSubview(label)
    }

    func addNote(_ text: String) {
        let label = NSTextField(wrappingLabelWithString: text)
        label.textColor = .secondaryLabelColor
        label.maximumNumberOfLines = 3
        stack.addArrangedSubview(label)
    }
}

private final class SwitchingVC: StackVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        let s = AppSettings.shared
        addTitle("Переключение")
        addNote("Автоматически исправляет слово, набранное в неверной RU/EN раскладке.")
        stack.addArrangedSubview(checkbox("Автопереключение", value: s.autoEnabled, action: { s.autoEnabled = $0 }))
        stack.addArrangedSubview(checkbox("Срабатывать по пробелу", value: s.autoSpace, action: { s.autoSpace = $0 }))
        stack.addArrangedSubview(checkbox("Срабатывать по Enter", value: s.autoEnter, action: { s.autoEnter = $0 }))
        stack.addArrangedSubview(checkbox("Срабатывать по Tab", value: s.autoTab, action: { s.autoTab = $0 }))
    }
}

private final class ExceptionsVC: StackVC {
    private let editor = NSTextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        addTitle("Исключения")
        addNote("Одно слово на строку. Эти слова автоматическое переключение не трогает.")

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

        addTitle("Автозамена")
        addNote("Сокращение = текст замены. Регистр и RU/EN раскладка сокращения не учитываются.")

        replacements.font = .systemFont(ofSize: 13)
        replacements.string = SnippetStore.shared.pairs.map { "\($0.0) = \($0.1)" }.joined(separator: "\n")
        stack.addArrangedSubview(makeScroll(replacements, height: 120))

        let row = NSStackView(views: [
            checkbox("Пробел", value: s.snippetExpandSpace, action: { s.snippetExpandSpace = $0 }),
            checkbox("Enter", value: s.snippetExpandEnter, action: { s.snippetExpandEnter = $0 }),
            checkbox("Tab", value: s.snippetExpandTab, action: { s.snippetExpandTab = $0 })
        ])
        row.orientation = .horizontal
        row.spacing = 14
        stack.addArrangedSubview(row)

        stack.addArrangedSubview(
            checkbox("Вставлять без форматирования (⇧⌘V)", value: s.plainPaste, action: { s.plainPaste = $0 })
        )
        stack.addArrangedSubview(
            checkbox("Исправлять опечатки", value: s.typoFix, action: { s.typoFix = $0 })
        )
        stack.addArrangedSubview(
            checkbox("Две заглавные подряд", value: s.twoCapsFix, action: { s.twoCapsFix = $0 })
        )
        stack.addArrangedSubview(
            checkbox("Менять регистр выделенного (⌃⌥U)", value: s.caseChangeEnabled, action: { s.caseChangeEnabled = $0 })
        )

        addNote("Сниппеты: название = текст. При включении: ⌃⌥S, затем цифра 1–9.")
        snippets.font = .systemFont(ofSize: 13)
        snippets.string = TextSnippetStore.shared.pairs.map { "\($0.0) = \($0.1)" }.joined(separator: "\n")
        stack.addArrangedSubview(makeScroll(snippets, height: 90))
        stack.addArrangedSubview(
            checkbox("Вставлять сниппет по сочетанию", value: s.snippetPickEnabled, action: { s.snippetPickEnabled = $0 })
        )

        let save = NSButton(title: "Сохранить списки", target: self, action: #selector(saveNow))
        stack.addArrangedSubview(save)
    }

    private func makeScroll(_ text: NSTextView, height: CGFloat) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.documentView = text
        scroll.hasVerticalScroller = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.widthAnchor.constraint(equalToConstant: 650).isActive = true
        scroll.heightAnchor.constraint(equalToConstant: height).isActive = true
        return scroll
    }

    @objc private func saveNow() {
        SnippetStore.shared.setPairs(parse(replacements.string))
        TextSnippetStore.shared.setPairs(parse(snippets.string))
    }

    private func parse(_ text: String) -> [(String, String)] {
        text.components(separatedBy: .newlines).compactMap { line in
            guard let range = line.range(of: "=") else { return nil }
            let left = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let right = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            return left.isEmpty ? nil : (left, right)
        }
    }
}

private final class GeneralVC: StackVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        addTitle("Общие")
        addNote("Lite не содержит Whisper, Parakeet, FluidAudio, Translation, Sparkle и постоянного наблюдателя буфера.")

        let access = NSButton(title: "Запросить доступ Accessibility…", target: self, action: #selector(requestAX))
        stack.addArrangedSubview(access)

        if #available(macOS 13.0, *) {
            let enabled = SMAppService.mainApp.status == .enabled
            let launch = checkbox("Запускать при входе в систему", value: enabled, action: { on in
                do {
                    if on {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    NSSound.beep()
                }
            })
            stack.addArrangedSubview(launch)
        }
    }

    @objc private func requestAX() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
