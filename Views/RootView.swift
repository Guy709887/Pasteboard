import SwiftUI
import UIKit

struct RootView: View {
    @Environment(ClipStore.self) private var store
    @Environment(PasteboardMonitor.self) private var monitor
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingSettings = false
    @State private var showingCompose = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            LibraryView()
                .navigationTitle("Pasteboard")
                .searchable(text: $store.searchText, prompt: "Search")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingCompose = true
                        } label: {
                            Label("Compose", systemImage: "square.and.pencil")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Toggle(isOn: captureBinding) {
                                Label("Auto-capture", systemImage: "dot.radiowaves.left.and.right")
                            }
                            Button {
                                store.clearHistory()
                                Haptics.tap()
                            } label: {
                                Label("Clear history", systemImage: "clock.arrow.circlepath")
                            }
                            .disabled(store.unpinned.isEmpty)

                            Divider()

                            Button {
                                showingSettings = true
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingCompose) { ComposeView() }
        .task {
            monitor.start { text in
                store.add(text)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { store.save() }
        }
    }

    private var captureBinding: Binding<Bool> {
        Binding(
            get: { store.isCapturing },
            set: { store.setAutoCapture($0) }
        )
    }
}
