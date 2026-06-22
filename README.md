# 🌊 FlowState | Gamified Habit Cultivation Engine

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Hive](https://img.shields.io/badge/Hive-NoSQL-yellow?style=for-the-badge)](https://pub.dev/packages/hive)
[![Status](https://img.shields.io/badge/Build-v2.0.0_Stable-success?style=for-the-badge)](https://github.com/1bitVscoder/flow-state-habit-rpg/releases/tag/v2.0.0)

> "Transform routine into a quest. Rise through the ranks of self-improvement by gamifying habits, battling bosses, and synchronizing with real-time solar phases."

**FlowState** is a high-fidelity, premium mobile application built with Flutter and Dart, designed to transform daily habit tracking into an immersive RPG adventure. Featuring a dynamic sky-phase rendering engine, local binary caching, layout constraints, and a customized boss fight tracker, this app gamifies daily task execution to optimize consistency.

---

## ✨ Features

* **🎬 Branded Splash Sequence:** Optimized native launch mask for clean background SQLite/Hive initialization without frame drops.
* **☀️🌕 Contextual Sky-Phase Engine:** Immersive, dynamic linear ambient gradients and layered Gaussian blur auroras that programmatically map to real-world solar cycles.
* **💾 Dual-Box Hive Persistence:** Lightweight, thread-safe NoSQL partition caching managing separate boxes for daily habit progress profiles and player status indicators.
* **⚔️ Raid Boss Subsystem ("The Glitch Lord"):** A real-time conditional health matrix tracking user task completion values to deal damage and award levels/experience.
* **📊 Matrix Profile Metrics:** Glassmorphic modal overlays presenting weekly consistency grids via modular vector rows.

---

## 🛠️ Tech Stack & Architecture

* **Framework:** Flutter (Dart UI Lifecycle & Constraint Engine)
* **Database Architecture:** Hive & Hive Flutter (Local Key-Value persistence on disk)
* **Animation & State:** Custom implicit animation controllers, layout constraint builders, and haptic feedback service bridges.

---

## 🚀 Installation & Setup

### For End Users (Quick APK Install)
1. Go to the [Releases](../../releases) section of this repository or download directly:
   * **[Download FlowState v2.0.0 APK](https://github.com/1bitVscoder/flow-state-habit-rpg/releases/download/v2.0.0/FlowState.apk)**
2. Open and install the APK on your Android device (ensure "Install from Unknown Sources" is allowed).

### For Developers (Build from Source)
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/1bitVscoder/flow-state-habit-rpg.git
   cd flow-state-habit-rpg
   ```
2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Build and Run:**
   ```bash
   flutter run
   ```
