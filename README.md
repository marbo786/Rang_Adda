<div align="center">

# 🎴 Rang-Adda

**A premium digital tabletop for classic South Asian card games — built with Flutter, real-time multiplayer, and a minimalist neon-dark aesthetic.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod%203.0-1E88E5)](https://riverpod.dev)
[![License](https://img.shields.io/badge/license-MIT-green)](#license)

</div>

---

## Overview

**Rang-Adda** ("the card hub") is a Flutter app that brings three classic trick-taking and bluffing card games — **Thulla**, **Bluff**, and **Rang** — onto a single polished, real-time multiplayer platform. It's built around a high-contrast, minimal-premium design system and a clean feature-first architecture, with full Firebase-backed online play alongside local pass-and-play.

This isn't a tech demo — it's a complete game engine: strict rule enforcement, trick resolution, team play, reconnection handling, lobbies, profiles, and live chat, all wired together with Riverpod and Firestore.

---

## Game Modes

### 🃏 Thulla
A fast-paced trick-taking game with strict suit-following rules. The engine automatically validates legal plays and determines trick winners — no house-ruling required.

### 🎭 Bluff / BS / Cheat
The classic game of deception. Players claim ranks on cards they may or may not actually hold, and opponents decide whether to call the bluff. Round-starters must play 2–4 cards; everyone else has the same range. The "Interrogator" is a frosted-glass call-bluff-or-accept dialog that keeps the tension readable at a glance.

### 🂠 Rang
A traditional South Asian 4-player team trick-taking game. Dynamic trump-caller assignment, full team-based scoring to 7 "Sars" (tricks), and automatic detection of a **Kot** (a clean sweep win). *(Currently WIP.)*

All three modes support both **online multiplayer** and **local pass & play**.

---

## Online Multiplayer

- **Real-time sync** across devices via Firestore, with Riverpod streaming state into the UI
- **Reconnection handling** — close the app or crash mid-game and rejoin straight from the lobby
- **Host-controlled lobbies** — kick inactive players, hide "Start Game" from non-hosts
- **Profiles & leaderboards** — wins/losses tracked per authenticated player
- **In-game chat & emoji reactions** rendered live over player avatars
- **Locked-down Firestore rules** — only authenticated players in a room can mutate that room's state

---

## Architecture

Feature-first, not layer-first — each game and each cross-cutting concern owns its own folder:

```
lib/
├── features/
│   ├── bluff/      # Bluff game mode: rules, UI, state
│   ├── thulla/     # Thulla game mode: rules, UI, state
│   ├── rang/        # Rang game mode (WIP): team logic, trump calling, Kot detection
│   ├── lobby/        # Matchmaking, waiting rooms, room creation
│   └── profile/      # Player stats, profiles, leaderboards
└── shared/
    ├── models/        # Core game/player/room models
    ├── services/      # Auth + Firestore service layer
    └── widgets/        # Global UI components
```

---

## Design System

A **Minimal Premium** look, tuned for fast readability mid-game:

| Element | Detail |
|---|---|
| Palette | Deep dark backgrounds (`#0F1115`, `#1E232D`) with a striking primary accent (`#5B8CFF`) |
| Cards | 20px border radii, clean typography, soft drop shadows — no overpowering suit symbols |
| Motion | 120ms–350ms custom physics-curve animations for card plays and trick resolution |
| Interactions | "Pass Device" prompts use frosted-glass overlays for a seamless local hand-off |
| Feedback | Integrated audio + haptics for tactile, premium-feeling input |

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter / Dart |
| State Management | Riverpod 3.0 |
| Routing | GoRouter |
| Backend | Firebase (Firestore + Authentication) |
| Local Persistence | shared_preferences |
| Reactive Streams | rxdart |
| Audio | just_audio |
| Fonts | google_fonts |

---

## Getting Started

```bash
# Clone the repo
git clone https://github.com/marbo786/Rang_Adda.git
cd Rang_Adda

# Install dependencies
flutter pub get

# Run the app
flutter run
```

Run the test suite (native Dart game engines):

```bash
flutter test
```

> **Note:** Online multiplayer requires a Firebase project wired up via `firebase.json` / `firestore.rules`. Pass & play modes work fully offline out of the box.

---

## Contributing

Issues and PRs are welcome — especially around finishing up **Rang**, adding new game modes, or improving the multiplayer engine.

---

<div align="center">

Built by [Marbo](https://github.com/marbo786)

</div>
