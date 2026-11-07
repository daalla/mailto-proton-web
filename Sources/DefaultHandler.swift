import AppKit
import CoreServices
import Foundation

enum DefaultMailtoHandler {
    static let bundleIdentifier = "com.daalla.mailtoviewer"
    static let mailBundleIdentifier = "com.apple.mail"
    static let mailAppURL = URL(fileURLWithPath: "/System/Applications/Mail.app")

    static func applicationBundleURL() -> URL {
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension == "app" {
            return bundleURL
        }
        var url = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        for _ in 0..<5 {
            if url.pathExtension == "app" {
                return url
            }
            url.deleteLastPathComponent()
        }
        return bundleURL
    }

    static func currentHandlerIdentifier() -> String {
        if let cf = LSCopyDefaultHandlerForURLScheme("mailto" as CFString) {
            return (cf.takeRetainedValue() as String)
        }
        if let appURL = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "mailto:probe@example.com")!),
           let id = Bundle(url: appURL)?.bundleIdentifier {
            return id
        }
        return "(desconocido)"
    }

    static func setDefault(to appURL: URL, completion: @escaping (Error?) -> Void) {
        Task { @MainActor in
            do {
                try await NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenURLsWithScheme: "mailto")
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    static func setAsDefaultAndWait() {
        let appURL = applicationBundleURL()
        print("Registrando \(appURL.path) como handler de mailto:…")
        print("Si macOS muestra un diálogo de confirmación, aceptalo.")
        var finished = false
        setDefault(to: appURL) { error in
            if let error {
                fputs("Error: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
            print("OK handler actual: \(currentHandlerIdentifier())")
            finished = true
            exit(0)
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 90))
        if !finished {
            fputs("Timeout: macOS no confirmó el cambio. Si apareció un diálogo, aceptalo y volvé a intentar.\n", stderr)
            exit(2)
        }
    }

    static func restoreMailAndWait() {
        print("Restaurando Mail como handler de mailto:…")
        var finished = false
        setDefault(to: mailAppURL) { error in
            if let error {
                fputs("Error: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
            print("OK handler actual: \(currentHandlerIdentifier())")
            finished = true
            exit(0)
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 90))
        if !finished {
            fputs("Timeout: macOS no confirmó el cambio.\n", stderr)
            exit(2)
        }
    }
}
