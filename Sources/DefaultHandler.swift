import AppKit
import CoreServices
import Foundation

enum DefaultMailtoHandler {
    static let bundleIdentifier = "com.daalla.mailtoprotonweb"
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
        return "(unknown)"
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
        print("Registering \(appURL.path) as the mailto: handler…")
        print("If macOS shows a confirmation dialog, accept it.")
        var finished = false
        setDefault(to: appURL) { error in
            if let error {
                fputs("Error: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
            print("OK current handler: \(currentHandlerIdentifier())")
            finished = true
            exit(0)
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 90))
        if !finished {
            fputs("Timeout: macOS did not confirm the change. If a dialog appeared, accept it and try again.\n", stderr)
            exit(2)
        }
    }

    static func restoreMailAndWait() {
        print("Restoring Mail as the mailto: handler…")
        var finished = false
        setDefault(to: mailAppURL) { error in
            if let error {
                fputs("Error: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
            print("OK current handler: \(currentHandlerIdentifier())")
            finished = true
            exit(0)
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 90))
        if !finished {
            fputs("Timeout: macOS did not confirm the change.\n", stderr)
            exit(2)
        }
    }
}
