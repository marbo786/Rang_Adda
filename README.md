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
  - **Round Starts:** The first player in a round MUST play 2, 3, or 4 cards to start the pile. (If they only have 1 card left, they must pass).
  - **Ongoing Play:** Subsequent players can play 1, 2, 3, or 4 cards.
  - **Any Rank, Any Time:** Players can claim *any* rank they want on their turn. There is no required sequence!
  - **The Interrogator:** When your turn starts, you are presented with a clean frosted-glass dialog to either CALL BLUFF on the previous player, or ACCEPT & PLAY.
  - The game engine handles all logic and card validation natively in Dart.
- **Mode:** Local Pass & Play supported.

### 3. Rang (Coming Soon)
The traditional South Asian trick-taking game is next on the roadmap!

## Design System

The application is built on a **Minimal Premium Design System**:
- **Palette:** Deep dark backgrounds (`#0F1115`, `#1E232D`) with striking primary accents (`#5B8CFF`).
- **Cards:** Crisp geometry with 20px border radii, clean typography without overpowering symbols, and soft drop shadows.
- **Motion:** Fast and responsive animations (120ms - 350ms) for card interactions and trick resolutions using custom physics curves.
- **Interactions:** "Pass Device" prompts use frosted-glass overlays to keep the game flow elegant.

## Online Multiplayer 🌐
The app now supports real-time online multiplayer powered by Firebase Firestore!
- **Real-Time Sync**: True cross-device state management using Riverpod.
- **Robust Reconnection**: If the app is closed or crashes, you can instantly reconnect to your active game straight from the Lobby.
- **Lobby Management**: The game host has full control over the waiting room and can kick inactive players.
- **Security Rules**: Locked down database rules ensure only authenticated players in the room can modify game state.

## Tech Stack

- **Framework:** Flutter / Dart
- **State Management:** Riverpod 3.0
- **Routing:** GoRouter
- **Backend:** Firebase (Firestore & Authentication)
- **Feedback:** Audio and Haptics engine integrated for premium tactile feedback.

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
