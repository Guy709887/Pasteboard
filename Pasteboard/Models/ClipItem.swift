import Foundation

enum ClipKind: String, Codable, CaseIterable {
    case text
    case url
    case code
    case email
    case number
    case phone

    var label: String {
        switch self {
        case .text: "Text"
        case .url: "Link"
        case .code: "Code"
        case .email: "Email"
        case .number: "Number"
        case .phone: "Phone"
        }
    }

    var symbol: String {
        switch self {
        case .text: "text.alignleft"
        case .url: "link"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .email: "envelope"
        case .number: "number"
        case .phone: "phone"
        }
    }
}

struct ClipItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var content: String
    var createdAt: Date
    var kind: ClipKind
    var isPinned: Bool = false

    init(content: String, createdAt: Date, kind: ClipKind? = nil, isPinned: Bool = false) {
        self.content = content
        self.createdAt = createdAt
        self.kind = kind ?? ClipClassifier.classify(content)
        self.isPinned = isPinned
    }

    /// True when the text is long enough that the row should clamp it.
    var isMultiline: Bool {
        content.contains("\n") || content.count > 140
    }

    var singleLine: String {
        content.replacingOccurrences(of: "\n", with: " ")
    }
}
