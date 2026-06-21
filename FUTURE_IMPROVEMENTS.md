# Future Improvements & To-Do List

This document outlines the remaining features and potential enhancements for the Rang-Adda project, specifically tailored for the team to pick up next.

## 🃏 For The Teammates: Rang Integration
The core logic engine (`RangEngine` and `RangGameState`) and the test suite are fully operational and passing! The next step is building the frontend.
- [ ] **Rang UI/UX Implementation**: Build out `rang_table_screen.dart` using the existing design tokens (cards, chips, and overlays).
- [ ] **Trump Selection UI**: Implement the UI for the dealer/trump-caller to easily declare the Trump Suit during the `trumpSelection` phase.
- [ ] **Online Play for Rang**: Create `online_rang_provider.dart` and integrate `OnlineActionController` to sync Rang's state across devices.

## 🚀 App Release Preparation
- [ ] **App Icons**: Generate and configure high-resolution app icons for Android and iOS using the `flutter_launcher_icons` package.
- [ ] **Splash Screen**: Implement a seamless, branded launch screen using `flutter_native_splash`.
- [ ] **Localization**: Add `flutter_localizations` to support multiple languages (e.g., Hindi, Urdu, Punjabi, English).

## ✨ UX/UI Polish & Gamification
- [ ] **Player Profiles & Stats**: Track wins, losses, and play style to display on a local or cloud profile page.
- [ ] **Leaderboards**: Implement Firebase leaderboards to track the highest ranking players.
- [ ] **In-Game Chat / Emotes**: Add a quick-chat or emote system for online rooms since voice chat isn't implemented.
- [ ] **Dynamic Backgrounds**: Let players unlock or select different premium table backgrounds.

## ⚙️ Engine & Optimization
- [ ] **Offline Bots**: Build a simple AI opponent engine so players can practice games offline without requiring physical pass-and-play.
- [ ] **Connection Resilience**: Add explicit visual indicators for patchy internet connections during online play, such as "Waiting for Host..." or "Re-syncing...".
