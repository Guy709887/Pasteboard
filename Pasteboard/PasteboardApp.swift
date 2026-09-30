import Foundation
import SwiftUI

@main
struct PasteboardApp: App {
    @State private var store = ClipStore()
    @State private var monitor = PasteboardMonitor()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(monitor)
                .tint(Theme.accent)
        }
    }
}
