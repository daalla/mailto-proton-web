import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windows: [NSWindowController] = []
    private var receivedURL = false
    private var lastOpened: (String, Date)?

    func applicationWillFinishLaunching(_ notification: Notification) {
        buildMenu()
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        for arg in CommandLine.arguments.dropFirst() where arg.lowercased().hasPrefix("mailto:") {
            openMailto(arg)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self, !self.receivedURL else { return }
            self.showHelp()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            openMailto(url.absoluteString)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showHelp()
        }
        return true
    }

    @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue else { return }
        DispatchQueue.main.async { [weak self] in
            self?.openMailto(urlString)
        }
    }

    func openMailto(_ raw: String) {
        receivedURL = true
        if let last = lastOpened, last.0 == raw, Date().timeIntervalSince(last.1) < 1.0 {
            return
        }
        lastOpened = (raw, Date())
        let draft = MailtoParser.parse(raw)
        let controller = MailtoWindowController(draft: draft)
        retain(controller)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showHelp() {
        if windows.contains(where: { $0 is HelpWindowController && $0.window?.isVisible == true }) {
            windows.first(where: { $0 is HelpWindowController })?.window?.makeKeyAndOrderFront(nil)
            return
        }
        let controller = HelpWindowController()
        retain(controller)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func retain(_ controller: NSWindowController) {
        windows.append(controller)
        if let window = controller.window {
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
                self?.windows.removeAll { $0.window === window }
            }
        }
    }

    private func buildMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Acerca de Mailto Viewer", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        let setDefaultItem = appMenu.addItem(withTitle: "Establecer como app de correo predeterminada", action: #selector(setAsDefaultClicked(_:)), keyEquivalent: "")
        setDefaultItem.target = self
        let restoreItem = appMenu.addItem(withTitle: "Restaurar Mail como app predeterminada", action: #selector(restoreMailClicked(_:)), keyEquivalent: "")
        restoreItem.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Ocultar Mailto Viewer", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Salir de Mailto Viewer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        mainMenu.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edición")
        editItem.submenu = editMenu
        editMenu.addItem(withTitle: "Cortar", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copiar", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Pegar", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Seleccionar todo", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        mainMenu.addItem(editItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Ventana")
        windowItem.submenu = windowMenu
        windowMenu.addItem(withTitle: "Minimizar", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Cerrar", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        mainMenu.addItem(windowItem)
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }

    @objc private func setAsDefaultClicked(_ sender: Any?) {
        let appURL = DefaultMailtoHandler.applicationBundleURL()
        DefaultMailtoHandler.setDefault(to: appURL) { error in
            DispatchQueue.main.async {
                self.presentHandlerResult(error: error, success: "Mailto Viewer quedó como app de correo predeterminada.")
            }
        }
    }

    @objc private func restoreMailClicked(_ sender: Any?) {
        DefaultMailtoHandler.setDefault(to: DefaultMailtoHandler.mailAppURL) { error in
            DispatchQueue.main.async {
                self.presentHandlerResult(error: error, success: "Mail volvió a ser la app de correo predeterminada.")
            }
        }
    }

    private func presentHandlerResult(error: Error?, success: String) {
        let alert = NSAlert()
        if let error {
            alert.alertStyle = .warning
            alert.messageText = "No se pudo cambiar la app predeterminada"
            alert.informativeText = error.localizedDescription
        } else {
            alert.messageText = "Listo"
            alert.informativeText = "\(success)\nManejador actual: \(DefaultMailtoHandler.currentHandlerIdentifier())."
        }
        alert.runModal()
    }
}
