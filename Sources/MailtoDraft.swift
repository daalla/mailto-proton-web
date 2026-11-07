import Foundation

struct MailtoDraft: Equatable {
    var to: [String]
    var cc: [String]
    var bcc: [String]
    var subject: String
    var body: String
    var rawURL: String

    var toText: String { to.joined(separator: ", ") }
    var ccText: String { cc.joined(separator: ", ") }
    var bccText: String { bcc.joined(separator: ", ") }

    var summary: String {
        let lines = [
            "Para: \(toText)",
            "Cc: \(ccText)",
            "Cco: \(bccText)",
            "Asunto: \(subject)",
            "Cuerpo:",
            body
        ]
        return lines.joined(separator: "\n")
    }

    var inspectText: String {
        """
        to: \(toText)
        cc: \(ccText)
        bcc: \(bccText)
        subject: \(subject)
        body:
        \(body)
        raw: \(rawURL)
        """
    }
}

enum MailtoParser {
    static func parse(_ rawInput: String) -> MailtoDraft {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        var rest = trimmed
        if let range = rest.range(of: "mailto:", options: [.anchored, .caseInsensitive]) {
            rest = String(rest[range.upperBound...])
        }

        let parts = rest.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let toRaw = String(parts[0])
        let query = parts.count > 1 ? String(parts[1]) : ""

        var to = splitAddresses(decode(toRaw))
        var cc: [String] = []
        var bcc: [String] = []
        var subject = ""
        var body = ""

        if !query.isEmpty {
            for pair in query.split(separator: "&", omittingEmptySubsequences: true) {
                let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                let key = decode(String(kv[0])).lowercased()
                let value = kv.count > 1 ? decode(String(kv[1])) : ""
                switch key {
                case "to":
                    to.append(contentsOf: splitAddresses(value))
                case "cc":
                    cc.append(contentsOf: splitAddresses(value))
                case "bcc":
                    bcc.append(contentsOf: splitAddresses(value))
                case "subject":
                    subject = value
                case "body":
                    body = value
                default:
                    break
                }
            }
        }

        return MailtoDraft(to: to, cc: cc, bcc: bcc, subject: subject, body: body, rawURL: normalizeRaw(trimmed))
    }

    static func decode(_ value: String) -> String {
        let plusAsSpace = value.replacingOccurrences(of: "+", with: " ")
        return plusAsSpace.removingPercentEncoding ?? plusAsSpace
    }

    static func splitAddresses(_ value: String) -> [String] {
        value.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
    }

    static func normalizeRaw(_ raw: String) -> String {
        raw.lowercased().hasPrefix("mailto:") ? raw : "mailto:\(raw)"
    }
}

enum ProtonMail {
    /// Mismo template que Proton Mail web: MAILTO_PROTOCOL_HANDLER_PATH
    /// en applications/mail/src/app/constants.ts → `/inbox/#mailto=%s`
    static let composerTemplate = "https://mail.proton.me/inbox/#mailto=%s"

    static func composerURLString(for mailtoURL: String) -> String {
        let raw = MailtoParser.normalizeRaw(mailtoURL)
        return "https://mail.proton.me/inbox/#mailto=\(encodeURIComponent(raw))"
    }

    static func composerURL(for mailtoURL: String) -> URL? {
        URL(string: composerURLString(for: mailtoURL))
    }

    /// Equivalente a encodeURIComponent de JavaScript.
    static func encodeURIComponent(_ string: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_.!~*'()")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}
