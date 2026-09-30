# Pasteboard

A clipboard history app for iOS. Built with SwiftUI, no third-party dependencies.

## Why it exists

iOS wipes your clipboard roughly a minute after you copy, and every paste from
another app throws up a system banner. This keeps a searchable local history,
grouped by day, with pinned items that never expire.

## Features

- **Auto-capture** anything you copy, anywhere on the phone
- **Search** across the full history
- **Pin** items you want to keep permanently (never trimmed)
- **Day sections** with relative timestamps
- **Content classification** — links, code, email, numbers, phone numbers get
  distinct row icons, and code renders in monospace so indentation survives
- **Compose** — join several clips with a chosen separator, then copy once.
  Nothing touches the system pasteboard until the final copy, so you avoid a
  banner per fragment.
- **Swipe actions** to copy, pin, and delete
- **Export** your history to a text file
- **Light and dark mode**

## Privacy

History is stored as plain JSON in the app's own container. Nothing is uploaded.

Values that look like credentials are never stored at all:

- long hex strings (32+ chars)
- URLs with embedded `user:password@`
- anything matching `api_key`, `secret`, `token`, `password`, or `bearer`

## Build

There is no Mac in the loop. GitHub Actions runs the compile on a free macOS
runner and hands back an unsigned `.ipa`, which the signing tool of your choice
then re-signs on install.

1. Push to `main`, or use the workflow's **Run workflow** button.
2. Download the `Pasteboard-ipa` artifact from the run summary and unzip it.
3. Sideload `Pasteboard.ipa`.

### Sideloadly

Drag the `.ipa` in, connect the iPhone over USB, and hit Start. Then on the
phone: **Settings → General → VPN & Device Management**, trust the developer,
and enable **Settings → Privacy & Security → Developer Mode**.

A free Apple ID signs certificates that expire after 7 days, so re-run the
install about once a week. Your history survives, since it lives in the app's
container. A paid developer account extends this to a year.

### SideStore

Install SideStore once and it refreshes apps in the background over Wi-Fi,
which removes the weekly re-install. See the SideStore docs for setup.

## Icons

`Assets.xcassets/AppIcon.appiconset` has a single 1024×1024 slot. Drop in a
PNG named `AppIcon.png`; no other sizes are needed.

## Project layout

Everything under `Pasteboard/` belongs to an Xcode 16 synchronized group, so
new `.swift` files are picked up automatically. Just drop them in — no project
file edits. Files outside that folder are not compiled.

```
Pasteboard/
  PasteboardApp.swift       entry point
  Models/
    ClipItem.swift          item model and content kinds
    ClipStore.swift         @Observable store, persistence, privacy filter
    PasteboardMonitor.swift changeCount watcher
  Support/
    ClipClassifier.swift    content type detection
    Theme.swift             accent color, fonts, haptics
  Views/
    RootView.swift          navigation, toolbar, monitoring lifecycle
    LibraryView.swift       list, sections, swipe actions
    ClipRow.swift           single row
    DetailView.swift        full content, copy and open
    ComposeView.swift       multi-clip assembly
    SettingsView.swift      limits, privacy, export, danger zone
  Assets.xcassets/          AppIcon, AccentColor

Resources/Info.plist        background modes, orientations
```
