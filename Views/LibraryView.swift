import SwiftUI
import UIKit

struct LibraryView: View {
    @Environment(ClipStore.self) private var store
    @Environment(PasteboardMonitor.self) private var monitor

    var body: some View {
        List {
            if !store.pinned.isEmpty {
                Section("Pinned") {
                    ForEach(store.pinned) { item in
                        row(item)
                    }
                    .onDelete { store.remove(at: $0, in: store.pinned) }
                }
            }

            ForEach(store.sections, id: \.label) { section in
                Section {
                    ForEach(section.items) { item in
                        row(item)
                    }
                    .onDelete { store.remove(at: $0, in: section.items) }
                } header: {
                    HStack {
                        Text(section.label)
                        Spacer()
                        Text("\(section.items.count)")
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if store.items.isEmpty {
                emptyState
            } else if store.filteredUnpinned.isEmpty && store.pinned.isEmpty {
                noResults
            }
        }
        .animation(.default, value: store.items.count)
    }

    @ViewBuilder
    private func row(_ item: ClipItem) -> some View {
        NavigationLink {
            DetailView(item: item)
        } label: {
            ClipRow(item: item)
        }
        .simultaneousGesture(TapGesture().onEnded { copy(item) })
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                store.togglePin(item)
                Haptics.tap()
            } label: {
                Label(item.isPinned ? "Unpin" : "Pin",
                      systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            .tint(Theme.accent)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.remove(item)
                Haptics.warning()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                copy(item)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button {
                store.togglePin(item)
            } label: {
                Label(item.isPinned ? "Unpin" : "Pin",
                      systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            if let url = URL(string: item.content),
               ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Label("Open", systemImage: "safari")
                }
            }
            Divider()
            Button(role: .destructive) {
                store.remove(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func copy(_ item: ClipItem) {
        UIPasteboard.general.string = item.content
        monitor.noteSelfCopy(item.content)
        Haptics.success()
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing copied yet", systemImage: "doc.on.clipboard")
        } description: {
            Text("Copy something anywhere on your phone and it will show up here.")
        }
    }

    private var noResults: some View {
        ContentUnavailableView.search(text: store.searchText)
    }
}
