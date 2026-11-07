import AppKit
import Foundation

private final class ActionHandler: NSObject {
    let block: () -> Void
    init(_ block: @escaping () -> Void) { self.block = block }
    @objc func call(_ sender: Any?) { block() }
}

final class MailtoWindowController: NSWindowController, NSWindowDelegate {
    private let draft: MailtoDraft
    private var actions: [ActionHandler] = []

    init(draft: MailtoDraft) {
        self.draft = draft
        let title = draft.subject.isEmpty ? "Mailto Viewer" : draft.subject
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.minSize = NSSize(width: 560, height: 400)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        window.contentView = makeContent()
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeContent() -> NSView {
        let root = NSView()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)

        let toField = makeTextField(draft.toText)
        let ccField = makeTextField(draft.ccText)
        let bccField = makeTextField(draft.bccText)
        let subjectField = makeTextField(draft.subject)
        let (bodyScroll, bodyView) = makeBodyView(draft.body)

        stack.addArrangedSubview(row(label: "Para", field: toField, text: { toField.stringValue }))
        stack.addArrangedSubview(row(label: "Cc", field: ccField, text: { ccField.stringValue }))
        stack.addArrangedSubview(row(label: "Cco", field: bccField, text: { bccField.stringValue }))
        stack.addArrangedSubview(row(label: "Asunto", field: subjectField, text: { subjectField.stringValue }))

        let bodyRow = NSStackView()
        bodyRow.orientation = .horizontal
        bodyRow.alignment = .top
        bodyRow.spacing = 8
        let bodyLabel = makeLabel("Cuerpo")
        let bodyCopy = makeButton("Copiar") { [weak bodyView] button in
            self.copyText(bodyView?.string ?? "", button: button)
        }
        bodyLabel.widthAnchor.constraint(equalToConstant: 64).isActive = true
        bodyCopy.widthAnchor.constraint(equalToConstant: 88).isActive = true
        bodyScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        bodyRow.addArrangedSubview(bodyLabel)
        bodyRow.addArrangedSubview(bodyScroll)
        bodyRow.addArrangedSubview(bodyCopy)
        bodyRow.translatesAutoresizingMaskIntoConstraints = false
        bodyRow.setHuggingPriority(.defaultLow, for: .horizontal)
        stack.addArrangedSubview(bodyRow)
        bodyRow.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.alignment = .centerY
        buttons.spacing = 10
        buttons.addArrangedSubview(NSView()) // spacer
        let copyAll = makeButton("Copiar todo") { [weak self] button in
            guard let self else { return }
            self.copyText(self.draft.summary, button: button)
        }
        let proton = makeButton("Abrir en Proton") { [weak self] _ in
            self?.openInProton()
        }
        proton.keyEquivalent = "\r"
        let close = makeButton("Cerrar") { [weak self] _ in
            self?.window?.performClose(nil)
        }
        close.keyEquivalent = "\u{1b}"
        buttons.addArrangedSubview(copyAll)
        buttons.addArrangedSubview(proton)
        buttons.addArrangedSubview(close)
        stack.addArrangedSubview(buttons)
        buttons.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
        ])
        return root
    }

    private func row(label: String, field: NSTextField, text: @escaping () -> String) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        let l = makeLabel(label)
        l.widthAnchor.constraint(equalToConstant: 64).isActive = true
        let b = makeButton("Copiar") { button in
            self.copyText(text(), button: button)
        }
        b.widthAnchor.constraint(equalToConstant: 88).isActive = true
        row.addArrangedSubview(l)
        row.addArrangedSubview(field)
        row.addArrangedSubview(b)
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }

    private func makeLabel(_ title: String) -> NSTextField {
        let l = NSTextField(labelWithString: title)
        l.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }

    private func makeTextField(_ value: String) -> NSTextField {
        let tf = NSTextField(string: value)
        tf.isEditable = false
        tf.isSelectable = true
        tf.bezelStyle = .roundedBezel
        tf.maximumNumberOfLines = 2
        tf.lineBreakMode = .byTruncatingMiddle
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tf
    }

    private func makeBodyView(_ value: String) -> (NSScrollView, NSTextView) {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.borderType = .bezelBorder
        scroll.autohidesScrollers = true
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let tv = NSTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isRichText = false
        tv.string = value
        tv.font = NSFont.systemFont(ofSize: 13)
        tv.textContainerInset = NSSize(width: 6, height: 8)
        tv.minSize = NSSize(width: 0, height: 150)
        tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        tv.autoresizingMask = [.width]
        scroll.documentView = tv
        return (scroll, tv)
    }

    private func makeButton(_ title: String, action: @escaping (NSButton) -> Void) -> NSButton {
        let button = NSButton(title: title, target: nil, action: nil)
        button.bezelStyle = .rounded
        let handler = ActionHandler { [weak button] in
            guard let button else { return }
            action(button)
        }
        actions.append(handler)
        button.target = handler
        button.action = #selector(ActionHandler.call(_:))
        return button
    }

    private func copyText(_ text: String, button: NSButton) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        let old = button.title
        button.title = "Copiado"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak button] in
            button?.title = old
        }
    }

    private func openInProton() {
        let urlString = ProtonMail.composerURLString(for: draft.rawURL)
        guard let url = URL(string: urlString) ?? ProtonMail.composerURL(for: draft.rawURL) else {
            let alert = NSAlert()
            alert.messageText = "No se pudo armar la URL de Proton"
            alert.informativeText = urlString
            alert.runModal()
            return
        }
        NSWorkspace.shared.open(url)
    }
}

final class HelpWindowController: NSWindowController {
    private var actions: [ActionHandler] = []

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 340),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Mailto Viewer"
        window.isReleasedWhenClosed = false
        window.center()
        self.init(window: window)
        window.contentView = makeContent()
    }

    private func makeContent() -> NSView {
        let root = NSView()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)

        let title = NSTextField(labelWithString: "Mailto Viewer")
        title.font = NSFont.systemFont(ofSize: 22, weight: .semibold)

        let body = NSTextField(wrappingLabelWithString: """
        Cuando tocás un enlace mailto: en cualquier app, esta ventana muestra el destinatario, copia, asunto y cuerpo, sin pedirte una cuenta.

        Dejala como app de correo predeterminada para que macOS no abra Mail. Mail y tus cuentas no se tocan.

        Desde acá podés copiar los campos o abrir el borrador en Proton Mail (web).
        """)
        body.preferredMaxLayoutWidth = 460

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 10
        let setDefault = makeButton("Establecer como predeterminada") { [weak self] _ in
            self?.setAsDefault()
        }
        let close = makeButton("Cerrar") { [weak self] _ in
            self?.window?.performClose(nil)
        }
        close.keyEquivalent = "\u{1b}"
        buttons.addArrangedSubview(setDefault)
        buttons.addArrangedSubview(close)

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(body)
        stack.addArrangedSubview(buttons)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -24),
        ])
        return root
    }

    private func makeButton(_ title: String, action: @escaping (NSButton) -> Void) -> NSButton {
        let button = NSButton(title: title, target: nil, action: nil)
        button.bezelStyle = .rounded
        let handler = ActionHandler { [weak button] in
            guard let button else { return }
            action(button)
        }
        actions.append(handler)
        button.target = handler
        button.action = #selector(ActionHandler.call(_:))
        return button
    }

    private func setAsDefault() {
        let appURL = DefaultMailtoHandler.applicationBundleURL()
        DefaultMailtoHandler.setDefault(to: appURL) { error in
            DispatchQueue.main.async {
                let alert = NSAlert()
                if let error {
                    alert.alertStyle = .warning
                    alert.messageText = "No se pudo cambiar la app predeterminada"
                    alert.informativeText = error.localizedDescription
                } else {
                    alert.messageText = "Listo"
                    alert.informativeText = "Mailto Viewer es la app de correo predeterminada. El manejador actual es \(DefaultMailtoHandler.currentHandlerIdentifier())."
                }
                if let window = self.window {
                    alert.beginSheetModal(for: window)
                } else {
                    alert.runModal()
                }
            }
        }
    }
}
