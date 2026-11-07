import AppKit
import Foundation

private let usage = """
Mailto Viewer
  (sin argumentos)        Abre la ventana de ayuda
  mailto:...              Muestra el enlace
  --set-default           La deja como app de correo predeterminada
  --restore-mail          Restaura Mail (com.apple.mail) como predeterminada
  --query-default         Imprime el bundle id del handler actual de mailto:
  --print-proton URL      Imprime la URL del redactor de Proton Mail
  --inspect URL           Muestra los campos parseados y la URL de Proton
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
    fputs("Falta la URL mailto:\n", stderr)
    exit(1)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
