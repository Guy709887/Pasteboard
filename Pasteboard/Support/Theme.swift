import SwiftUI
import UIKit

enum Theme {
    /// Single restrained accent. Everything else leans on system colors and
    /// secondary hierarchy rather than gradients or shadows.
    static let accent = Color(red: 0.42, green: 0.45, blue: 0.50)

    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let separator = Color(.separator).opacity(0.4)

    /// Monospaced for anything the classifier flagged as code, so indentation
    /// and punctuation stay readable in a list row.
    static func font(for kind: ClipKind) -> Font {
        switch kind {
        case .code: .system(.subheadline, design: .monospaced)
        default: .system(.subheadline)
        }
    }
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
