import Foundation
import Observation
import SwiftUI

@Observable
final class ClipStore {
    private(set) var items: [ClipItem] = []

    /// Drives `filteredUnpinned`. Held here rather than in the view so the
    /// search field can bind straight to it.
    var searchText: String = ""

    /// @AppStorage is a View property wrapper, so it cannot live on an
    /// @Observable class. These mirror UserDefaults directly and stay
    /// observation-tracked.
    var maxItems: Int {
        didSet { defaults.set(maxItems, forKey: Keys.maxItems) }
    }

    var autoCapture: Bool {
        didSet { defaults.set(autoCapture, forKey: Keys.autoCapture) }
    }

    private enum Keys {
        static let maxItems = "maxItems"
        static let autoCapture = "autoCapture"
    }

    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        fileURL = base.appendingPathComponent("clips.json")

        maxItems = defaults.object(forKey: Keys.maxItems) as? Int ?? 200
        autoCapture = defaults.object(forKey: Keys.autoCapture) as? Bool ?? true

        load()
    }

    // MARK: Queries

    var pinned: [ClipItem] { items.filter(\.isPinned) }

    var unpinned: [ClipItem] { items.filter { !$0.isPinned } }

    var filteredUnpinned: [ClipItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return unpinned }
        return unpinned.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }

    var hasQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Groups unpinned items into day buckets, newest first.
    var sections: [(label: String, items: [ClipItem])] {
        let calendar = Calendar.current
        var order: [Date] = []
        var buckets: [Date: [ClipItem]] = [:]

        for item in filteredUnpinned {
            let day = calendar.startOfDay(for: item.createdAt)
            if buckets[day] == nil { order.append(day) }
            buckets[day, default: []].append(item)
        }

        let now = Date()
        return order.sorted(by: >).map { day in
            let label: String
            if calendar.isDateInToday(day) {
                label = "Today"
            } else if calendar.isDateInYesterday(day) {
                label = "Yesterday"
            } else if let days = calendar.dateComponents([.day], from: day, to: now).day,
                      days < 7 {
                label = day.formatted(.dateTime.weekday(.wide))
            } else {
                label = day.formatted(.dateTime.month(.abbreviated).day().year())
            }
            return (label, buckets[day] ?? [])
        }
    }

    // MARK: Mutations

    func add(_ content: String) {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSensitive(text) else { return }

        // Collapse an immediate duplicate of the newest entry.
        if items.first?.content == text { return }

        items.insert(ClipItem(content: text, createdAt: Date()), at: 0)
        trim()
        scheduleSave()
    }

    func remove(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        scheduleSave()
    }

    func remove(at offsets: IndexSet, in group: [ClipItem]) {
        let ids = offsets.map { group[$0].id }
        items.removeAll { ids.contains($0.id) }
        scheduleSave()
    }

    func togglePin(_ item: ClipItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        if items[index].isPinned {
            items.sort { ($0.isPinned ? 0 : 1, $0.createdAt) < ($1.isPinned ? 0 : 1, $1.createdAt) }
        }
        scheduleSave()
    }

    func clearHistory() {
        items.removeAll { !$0.isPinned }
        scheduleSave()
    }

    func deleteAll() {
        items.removeAll()
        scheduleSave()
    }

    func export() -> String {
        let formatter = ISO8601DateFormatter()
        var lines = items.map { item in
            let stamp = formatter.string(from: item.createdAt)
            let pin = item.isPinned ? "pinned" : "history"
            return "[\(stamp)] (\(pin), \(item.kind.rawValue)) \(item.singleLine)"
        }
        let pinnedCount = items.filter(\.isPinned).count
        lines.insert("Pasteboard export - \(items.count) items, \(pinnedCount) pinned", at: 0)
        return lines.joined(separator: "\n")
    }

    // MARK: Capture

    var isCapturing: Bool { autoCapture }

    // MARK: Privacy

    /// Skips values that look like credentials. Deliberately conservative: a
    /// 32+ char hex blob or a `user:pass@host` shape never gets stored.
    private func isSensitive(_ text: String) -> Bool {
        if text.range(of: #"^[A-Fa-f0-9]{32,}$"#, options: .regularExpression) != nil { return true }
        if text.contains("://") {
            if text.range(of: #"://[^/\s:@]+:[^/\s:@]+@"#, options: .regularExpression) != nil { return true }
        }
        if text.range(of: #"(?i)\b(api[_-]?key|secret|token|password|bearer)\b"#,
                      options: .regularExpression) != nil { return true }
        return false
    }

    // MARK: Persistence

    private func trim() {
        let configured = defaults.object(forKey: Keys.maxItems) as? Int ?? maxItems
        let limit = max(20, min(configured, 1000))
        let history = items.filter { !$0.isPinned }
        if history.count > limit {
            let excess = history.suffix(history.count - limit)
            let excessIDs = Set(excess.map(\.id))
            items.removeAll { excessIDs.contains($0.id) }
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.save()
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        items = (try? decoder.decode([ClipItem].self, from: data)) ?? []
        items.sort { ($0.isPinned ? 0 : 1, $0.createdAt) < ($1.isPinned ? 0 : 1, $1.createdAt) }
    }
}
