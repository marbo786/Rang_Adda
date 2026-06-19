# Rang-Adda Roadmap & Future Improvements

This document tracks upcoming features, polish items, and architectural improvements that are yet to be implemented.

## 🚧 High-Priority / Immediate Todos

### Online Multiplayer Integration
- **Firebase Realtime Sync:** Replace the mocked local providers with live Firebase snapshot listeners.
- **Lobby System:** Complete the lobby UI where players can join via a room code, select their seats, and ready up.
- **Matchmaking / Presence:** Implement Firebase Presence to handle player disconnections gracefully.

### "Rang" Game Mode Implementation
- **Game Engine:** Build the native Dart engine for Rang, handling trump suit (Rang) selection logic, team scoring, and strict suit-following logic.
- **UI Table Screen:** Create `RangTableScreen` with a 4-player cross layout (North, East, South, West) optimized for tablet and mobile landscape.

## ✨ Polish & UX Improvements

### Audio Design
- **SFX:** Add satisfying, high-quality sounds for:
  - Card flips & swooshes
  - Error buzzes (e.g., trying to play an invalid card)
  - Victory / Defeat fanfares
  - A heavy "slam" sound effect when someone gets called out on a Bluff.
- **Haptic Feedback:** Implement `HapticFeedback.lightImpact()` on card selections and `heavyImpact()` on Bluff calls to make the app feel incredibly tactile.

### Advanced Visuals & Animations
- **Confetti/Particle Effects:** Trigger particle explosions when a trick is won or a Bluff is successfully called.
- **Card Distribution Animation:** Currently cards appear instantly in hand. Animate the dealer dealing cards one by one from the center pile.
- **Dynamic Avatars:** Allow users to pick cool profile pictures or 3D avatars that glow/pulsate when it's their turn.

## 🏗️ Technical & Architecture

- **State Management Optimization:** Once Firebase is integrated, ensure Riverpod state doesn't memory leak on heavy network reconnections.
- **Offline Resilience:** If playing online, queue moves locally if the connection drops and sync them up when reconnected.

## 🚀 App Store / Release Prep
- **App Icons & Splash Screen:** Generate final high-resolution app icons and a native splash screen (via `flutter_native_splash`).
- **Performance Profiling:** Run the app in Profile mode to ensure 120fps scrolling and animations on high refresh-rate devices.
- **Localization:** Prepare the app for multiple languages (English, Urdu, Hindi) using `flutter_localizations`.
