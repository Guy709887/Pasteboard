import Foundation
import Observation
import UIKit

/// Watches `UIPasteboard.changeCount` rather than reading contents on a timer.
///
/// This is the important part: iOS only shows the "Pasted from <app>" banner
/// when another app actually reads clipboard *contents*. Polling `changeCount`
/// and only reading `string` when the count moves keeps the prompt rare and
/// correctly attributed.
@Observable
final class PasteboardMonitor {
    private(set) var isRunning = false
    private(set) var lastSeenChangeCount: Int = 0

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var lastCopiedByUs: String = ""
    @ObservationIgnored private var onCapture: ((String) -> Void)?

    private let interval: TimeInterval = 0.6

    func start(onCapture: @escaping (String) -> Void) {
        self.onCapture = onCapture
        lastSeenChangeCount = UIPasteboard.general.changeCount
        guard timer == nil else { return }

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // .common keeps it firing while scrolling, so captures don't gap.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        isRunning = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    /// Called after we copy an item back out, so we don't immediately re-capture it.
    func noteSelfCopy(_ text: String) {
        lastCopiedByUs = text
        lastSeenChangeCount = UIPasteboard.general.changeCount
    }

    private func tick() {
        let pasteboard = UIPasteboard.general
        guard pasteboard.changeCount != lastSeenChangeCount else { return }
        lastSeenChangeCount = pasteboard.changeCount

        // Skip the echo of a copy this app just performed.
        if !lastCopiedByUs.isEmpty, pasteboard.string == lastCopiedByUs {
            lastCopiedByUs = ""
            return
        }
        lastCopiedByUs = ""

        guard let text = pasteboard.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }

        onCapture?(text)
    }
}
