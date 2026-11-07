import AppKit
import Foundation

enum Preferences {
    static let openDirectlyKey = "openDirectlyInProton"

    /// Por defecto está encendido (abrir Proton sin ventana).
    static var openDirectlyInProton: Bool {
        get {
            if UserDefaults.standard.object(forKey: openDirectlyKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: openDirectlyKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: openDirectlyKey)
        }
    }

    static var optionKeyIsDown: Bool {
        NSEvent.modifierFlags.contains(.option)
    }
}

enum BrowserLauncher {
    static let chromeBundleId = "com.google.Chrome"

    static func open(_ url: URL, completion: @escaping (Error?) -> Void) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        if let chromeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: chromeBundleId) {
            NSWorkspace.shared.open([url], withApplicationAt: chromeURL, configuration: config) { _, error in
                if error != nil {
                    NSWorkspace.shared.open(url)
                }
                completion(error)
            }
        } else {
            NSWorkspace.shared.open(url)
            completion(nil)
        }
    }
}
