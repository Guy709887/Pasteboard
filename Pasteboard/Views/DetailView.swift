import SwiftUI
import UIKit

struct DetailView: View {
    @Environment(ClipStore.self) private var store
    @Environment(PasteboardMonitor.self) private var monitor
    @Environment(\.dismiss) private var dismiss

    let item: ClipItem

    @State private var copied = false

    private var current: ClipItem {
        store.items.first { $0.id == item.id } ?? item
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(current.content)
                    .font(Theme.font(for: current.kind))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .background(Theme.cardBackground)
        .navigationTitle(current.kind.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        store.togglePin(current)
                        Haptics.tap()
                    } label: {
                        Label(current.isPinned ? "Unpin" : "Pin",
                              systemImage: current.isPinned ? "pin.slash" : "pin")
                    }
                    ShareLink(item: current.content) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(role: .destructive) {
                        store.remove(current)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                copy()
            } label: {
                Label(copied ? "Copied" : "Copy",
                      systemImage: copied ? "checkmark" : "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let url = URL(string: current.content),
               ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Label("Open", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func copy() {
        UIPasteboard.general.string = current.content
        monitor.noteSelfCopy(current.content)
        withAnimation(.snappy) { copied = true }
        Haptics.success()
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.snappy) { copied = false }
        }
    }
}
