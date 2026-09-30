import SwiftUI
import UIKit

/// Stacks several clips into one buffer, then copies the result. The point is
/// that nothing is written to the system pasteboard until the final copy, so
/// you avoid the "Pasted from" banner for every intermediate step.
struct ComposeView: View {
    @Environment(ClipStore.self) private var store
    @Environment(PasteboardMonitor.self) private var monitor
    @Environment(\.dismiss) private var dismiss

    @State private var assembly: [ClipItem] = []
    @State private var separator: Separator = .newline
    @State private var copied = false

    enum Separator: String, CaseIterable, Identifiable {
        case newline = "New line"
        case space = "Space"
        case tab = "Tab"
        case none = "None"

        var id: String { rawValue }

        var glue: String {
            switch self {
            case .newline: "\n"
            case .space: " "
            case .tab: "\t"
            case .none: ""
            }
        }
    }

    private var output: String {
        assembly
            .map(\.singleLine)
            .joined(separator: separator.glue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if assembly.isEmpty {
                        Text("Pick clips from your history to join them together.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(assembly.enumerated()), id: \.element.id) { index, item in
                                HStack(alignment: .top) {
                                    Text(item.singleLine)
                                        .font(Theme.font(for: item.kind))
                                        .lineLimit(2)
                                    Spacer(minLength: 8)
                                    Button {
                                        assembly.remove(at: index)
                                        Haptics.tap()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Divider()

                            Text(output.isEmpty ? "—" : output)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                } header: {
                    Text("Assembly")
                }

                Section {
                    Picker("Separator", selection: $separator) {
                        ForEach(Separator.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Join with")
                }

                Section {
                    ForEach(store.items.prefix(40)) { item in
                        Button {
                            assembly.append(item)
                            Haptics.tap()
                        } label: {
                            ClipRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("History")
                }
            }
            .navigationTitle("Compose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        copyAll()
                    } label: {
                        Label(copied ? "Copied" : "Copy all",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    .disabled(assembly.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    if !assembly.isEmpty {
                        Button {
                            assembly.removeAll()
                        } label: {
                            Label("Clear all", systemImage: "trash")
                        }
                        .font(.footnote)
                    }
                }
            }
        }
    }

    private func copyAll() {
        UIPasteboard.general.string = output
        monitor.noteSelfCopy(output)
        withAnimation(.snappy) { copied = true }
        Haptics.success()
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.snappy) { copied = false }
        }
    }
}
