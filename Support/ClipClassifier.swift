import Foundation

enum ClipClassifier {
    private static let emailPattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    private static let codeHints: [String] = [
        "func ", "let ", "var ", "import ", "class ", "struct ", "enum ",
        "def ", "const ", "return", "=>", "->", "{", "}", "();", "</",
        "public ", "private ", "async ", "await ", "#include", "<?php",
    ]

    static func classify(_ raw: String) -> ClipKind {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return .text }

        if let url = URL(string: text), let scheme = url.scheme,
           ["http", "https", "ftp"].contains(scheme.lowercased()),
           url.host?.isEmpty == false {
            return .url
        }

        if text.range(of: emailPattern, options: .regularExpression) != nil {
            return .email
        }

        if text.allSatisfy({ $0.isNumber || $0 == " " || $0 == "." || $0 == "," || $0 == "-" }),
           text.contains(where: \.isNumber) {
            return .number
        }

        let lower = text.lowercased()
        if text.contains("\n") || codeHints.contains(where: { lower.contains($0) }) {
            return .code
        }

        let digits = text.filter(\.isNumber)
        let stripped = text.filter { !$0.isWhitespace && $0 != "-" && $0 != "+" && $0 != "(" && $0 != ")" }
        if digits.count >= 7, digits.count == stripped.count, text.count <= 24 {
            return .phone
        }

        return .text
    }
}
