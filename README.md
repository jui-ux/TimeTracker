# TimeTracker

A minimal macOS menu bar app for tracking time across client projects.

Built with SwiftUI and SwiftData. Lives in your menu bar — no Dock icon.

![macOS](https://img.shields.io/badge/macOS-14%2B-black) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

---

## Features

- **Menu bar timer** — start and stop sessions from anywhere
- **Multiple clients** — switch between clients, colour-coded
- **Session history** — browse, search, filter and edit past sessions
- **Project types** — tag sessions as Wireframe, Hi-Fi, Research, Review
- **CSV export** — export sessions per client or all at once
- **Keyboard shortcut** — ⌥⌘T toggles the current session globally

## Requirements

- macOS 14 Sonoma or later
- Xcode 15 or later

## Getting Started

```bash
git clone https://github.com/jui-ux/TimeTracker.git
cd TimeTracker
open TimeTracker.xcodeproj
```

Xcode will automatically resolve the [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) dependency on first open.

Before running, set your development team:

1. Click the **TimeTracker** project in the file navigator
2. Select the **TimeTracker** target
3. Open **Signing & Capabilities**
4. Set **Team** to your Apple Developer account

Then press **⌘R** to build and run.

## Project Structure

```
TimeTracker/
├── Models/
│   ├── Client.swift          # SwiftData model — client with colour + sort order
│   └── Session.swift         # SwiftData model — time entry linked to a client
├── Store/
│   └── TimerStore.swift      # Observable app state — active client, running session
├── Views/
│   ├── MainWindowView.swift  # Main window — header, hero card, sessions table
│   ├── ClientManagerView.swift # Client add / edit / delete / reorder popover
│   ├── HeroCardView.swift    # Idle and running hero cards
│   ├── SessionsTableView.swift # Sessions list with inline editing
│   ├── SessionEditView.swift  # Full session edit sheet
│   ├── MenuBarPillView.swift  # Menu bar pill label
│   └── Components/           # Shared UI — tokens, switcher, filter pills, type chips
└── Intents/
    └── TrackingIntents.swift # App Intents for Shortcuts integration
```

## License

MIT
