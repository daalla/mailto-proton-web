import AppKit
import Foundation

private let usage = """
Mailto Proton Web
  (no arguments)         Open preferences
  mailto:...              Open Proton directly (hold Option to view fields)
  --set-default           Set this app as the default mailto: handler
  --restore-mail          Restore Mail (com.apple.mail) as the default
  --query-default         Print the current mailto: handler bundle ID
  --print-proton URL      Print the Proton Mail composer URL
  --inspect URL           Print parsed fields and the Proton URL
"""

let args = CommandLine.arguments

if args.contains("--help") || args.contains("-h") {
    print(usage)
    exit(0)
}

if args.contains("--query-default") {
    print(DefaultMailtoHandler.currentHandlerIdentifier())
    exit(0)
}

if args.contains("--set-default") {
    DefaultMailtoHandler.setAsDefaultAndWait()
}

if args.contains("--restore-mail") {
    DefaultMailtoHandler.restoreMailAndWait()
}

if let i = args.firstIndex(of: "--print-proton"), args.indices.contains(i + 1) {
    print(ProtonMail.composerURLString(for: args[i + 1]))
    exit(0)
}

if let i = args.firstIndex(of: "--inspect"), args.indices.contains(i + 1) {
    let mailto = args[i + 1]
    let draft = MailtoParser.parse(mailto)
    print(draft.inspectText)
    print("proton: \(ProtonMail.composerURLString(for: mailto))")
    exit(0)
}

if args.contains("--print-proton") || args.contains("--inspect") {
    fputs("Missing mailto: URL\n", stderr)
    exit(1)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
