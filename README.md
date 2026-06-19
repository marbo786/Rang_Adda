# Rang-Adda

Welcome to **Rang-Adda**, a premium digital tabletop experience for classic card games! This application is built with Flutter and designed with a minimalist, high-contrast aesthetic that focuses on smooth interactions and an engaging multiplayer feel.

## Current Game Modes

### 1. Thulla (Pass & Play)
A fast-paced trick-taking game where players must follow suit if possible, or play a power card. 
- **Objective:** Win tricks by playing the highest card of the led suit or a powerful trump card.
- **Rules:** The game enforces strict suit-following and automatically determines trick winners.
- **Mode:** Local Pass & Play supported.

### 2. Bluff / BS / Cheat (Pass & Play)
The classic game of deception and card-counting!
- **Objective:** Be the first player to get rid of all your cards by successfully bluffing or telling the truth.
- **Mechanics:** 
  - Play 1 to 4 cards on your turn and claim a rank.
  - Ranks strictly increment every turn (Ace -> 2 -> 3...).
  - **The Interrogator:** When your turn starts, you are presented with a clean glass-dialog to either CALL BLUFF on the previous player, or ACCEPT & PLAY.
  - The game engine handles all logic natively in Dart.
- **Mode:** Local Pass & Play supported.

### 3. Rang (Coming Soon)
The traditional South Asian trick-taking game is next on the roadmap!

## Design System

The application is built on a **Minimal Premium Design System**:
- **Palette:** Deep dark backgrounds (`#0F1115`, `#1E232D`) with striking primary accents (`#5B8CFF`).
- **Cards:** Crisp geometry with 20px border radii, clean typography without overpowering symbols, and soft drop shadows.
- **Motion:** Fast and responsive animations (120ms - 350ms) for card interactions and trick resolutions using custom physics curves.
- **Interactions:** "Pass Device" prompts use frosted-glass overlays to keep the game flow elegant.

## Tech Stack

- **Framework:** Flutter / Dart
- **State Management:** Riverpod 3.0
- **Routing:** GoRouter
- **Backend:** Firebase (Firestore) - *(Integration for online play in progress)*

## Running the Project

Ensure you have Flutter installed.

```bash
flutter pub get
flutter run
```

To run tests on the native Dart game engines:
```bash
flutter test
```

## Contributing
Feel free to open an issue or pull request if you want to add new games or improve the engine!
