import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(ClipStore.self) private var store
    @Environment(PasteboardMonitor.self) private var monitor
    @Environment(\.dismiss) private var dismiss

    @AppStorage("confirmBeforeDelete") private var confirmBeforeDelete: Bool = false

    @State private var showingClearAll = false
    @State private var showingExporter = false
    @State private var exportText = ""

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    LabeledContent("Monitoring", value: monitor.isRunning ? "Active" : "Paused")
                    LabeledContent("Stored items", value: "\(store.items.count)")
                    LabeledContent("Pinned", value: "\(store.pinned.count)")
                } header: {
                    Text("Status")
                } footer: {
                    Text("Capture only works while the app has been opened at least once, since iOS does not launch apps on their own.")
                }

                Section {
                    Picker("Keep at most", selection: $store.maxItems) {
                        Text("50").tag(50)
                        Text("200").tag(200)
                        Text("500").tag(500)
                        Text("1000").tag(1000)
                    }
                } header: {
                    Text("History limit")
                } footer: {
                    Text("Pinned items are never trimmed.")
                }

                Section {
                    Toggle("Confirm before clearing", isOn: $confirmBeforeDelete)
                } header: {
                    Text("Safety")
                } footer: {
                    Text("Values that look like API keys, bearer tokens, or embedded URL credentials are never stored, regardless of these settings.")
                }

                Section {
                    Button {
                        exportText = store.export()
                        showingExporter = true
                    } label: {
                        Label("Export as text", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        store.clearHistory()
                        Haptics.tap()
                    } label: {
                        Label("Clear unpinned history", systemImage: "clock.arrow.circlepath")
                    }
                    .disabled(store.unpinned.isEmpty)

                    Button(role: .destructive) {
                        showingClearAll = true
                    } label: {
                        Label("Delete everything", systemImage: "trash")
                    }
                } header: {
                    Text("Data")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete everything?", isPresented: $showingClearAll) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    store.deleteAll()
                    Haptics.warning()
                }
            } message: {
                Text("This removes all \(store.items.count) items, including pinned ones. It cannot be undone.")
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: TextDocument(text: exportText),
                contentType: .plainText,
                defaultFilename: "pasteboard-export"
            ) { _ in }
        }
    }
}

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            text = ""
            return
        }
        text = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
