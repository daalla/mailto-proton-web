import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windows: [NSWindowController] = []
    private var receivedURL = false
    private var lastOpened: (String, Date)?
    private var isQuittingAfterProton = false

    func applicationWillFinishLaunching(_ notification: Notification) {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self, !self.receivedURL, !self.isQuittingAfterProton else { return }
            self.showPreferences()
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
        if !flag && !isQuittingAfterProton {
            showPreferences()
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

        let showViewerWindow = Preferences.optionKeyIsDown || !Preferences.openDirectlyInProton
        if showViewerWindow {
            showViewer(raw)
            return
        }
        openProtonHeadlessAndQuit(raw)
    }

    private func openProtonHeadlessAndQuit(_ raw: String) {
        let urlString = ProtonMail.composerURLString(for: raw)
        guard let url = URL(string: urlString) else {
            showViewer(raw)
            return
        }
        isQuittingAfterProton = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            NSApp.terminate(nil)
        }
        BrowserLauncher.open(url) { _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    func showViewer(_ raw: String) {
        let draft = MailtoParser.parse(raw)
        let controller = MailtoWindowController(draft: draft)
        retain(controller)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showPreferences() {
        if windows.contains(where: { $0 is PreferencesWindowController && $0.window?.isVisible == true }) {
            windows.first(where: { $0 is PreferencesWindowController })?.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = PreferencesWindowController()
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
}
