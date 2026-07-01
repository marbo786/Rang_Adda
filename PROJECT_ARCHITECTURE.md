# 🎴 Rang-Adda: Project & Architecture Overview

## 1. Project Overview

**Rang-Adda** ("the card hub") is a premium digital tabletop for classic South Asian card games built with **Flutter**. It brings three popular trick-taking and bluffing card games onto a single, real-time multiplayer platform:

1. **Thulla**: A fast-paced trick-taking game with strict suit-following rules.
2. **Bluff / BS / Cheat**: A classic game of deception where players claim ranks on hidden cards, featuring a frosted-glass "Interrogator" dialog.
3. **Rang (Court Piece)**: A traditional South Asian 4-player team trick-taking game (2v2) with dynamic trump-caller assignment (Sir), strict suit-following logic, and automatic detection of clean sweeps (Kot/Bavney).

### Key Features
*   **Real-time Multiplayer**: Powered by Firebase Firestore, offering real-time synchronization, matchmaking, host-controlled lobbies, and reconnect handling.
*   **Local Play**: Full offline "pass & play" support, complete with Bot/AI integration.
*   **Social & Progression**: Player profiles, win/loss tracking, leaderboards, and in-game chat with emoji reactions.
*   **Minimal-Premium Design**: Deep dark backgrounds (`#0F1115`, `#1E232D`), high-contrast neon accents, 120-350ms custom physics-curve animations, and integrated audio/haptics.

---

## 2. Technology Stack

*   **Frontend**: Flutter (Dart)
*   **State Management**: Riverpod 3.0
*   **Routing**: GoRouter
*   **Backend / BaaS**: Firebase (Firestore for real-time DB, Firebase Auth for authentication)
*   **Local Persistence**: `shared_preferences`
*   **Reactive Streams**: `rxdart`
*   **Audio**: `just_audio`
*   **Fonts**: `google_fonts`

---

## 3. Architecture

The codebase follows a **Feature-First Architecture** rather than a traditional layer-first approach. Each game mode and cross-cutting concern is isolated in its own directory, owning its respective rules, UI, and state.

### Codebase Structure (`lib/`)

```text
lib/
├── data/           # Data layer, handling external data sources and local persistence
├── features/       # Feature-driven modules (Game modes & core app sections)
│   ├── bluff/      # Bluff game mode: game rules, specific UI, and local state
│   ├── lobby/      # Matchmaking, room creation, and waiting rooms
│   ├── profile/    # User profiles, statistics, and leaderboards
│   ├── rang/       # Rang mode: 2v2 logic, trump calling, and Kot detection
│   └── thulla/     # Thulla game mode: trick-resolution and rule enforcement
├── shared/         # Shared resources, utilities, and global components
│   ├── ai/         # Bot/AI logic for offline pass-and-play modes
│   ├── models/     # Core domain models (Cards, Deck, Player, Room)
│   ├── routing/    # GoRouter configuration and route definitions
│   ├── services/   # Infrastructure services (Firebase Auth, Firestore interactions)
│   ├── state/      # Global application state (Authentication status, global settings)
│   └── ui/         # Reusable widgets, theme definitions, and design system tokens
├── firebase_options.dart # Auto-generated Firebase initialization config
└── main.dart       # Application entry point
```

### Architectural Principles

1.  **Separation of Concerns via Riverpod**: State logic is heavily decoupled from UI widgets using Riverpod providers. Real-time Firestore streams are consumed by providers to automatically rebuild the UI when game state changes.
2.  **Modular Game Engines**: Each game (Bluff, Thulla, Rang) acts as an independent "engine" under `features/`. They enforce their own rules and handle local tricks/plays without polluting the global state.
3.  **Secure Backend Rules**: Firestore security rules (`firestore.rules`) ensure that only authenticated players currently inside a specific room can mutate that room's state, preventing cheating and unauthorized access.
4.  **Responsive & Performant UI**: The design system relies heavily on custom physics curves for animations (card dealing, trick taking) and prioritizes readable UI even in fast-paced moments.
