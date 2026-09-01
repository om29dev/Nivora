# Nivora ⚡
> **AI-Native Mobile Development Workstation for Android**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-SDK_28+-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-00D2B4?style=for-the-badge)](https://riverpod.dev)
[![On--Device AI](https://img.shields.io/badge/AI-On--Device_SLMs_%2B_Cloud-FF6F00?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![Nix](https://img.shields.io/badge/Nix-Flakes_Ready-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue?style=for-the-badge)](LICENSE)

`#flutter` `#android` `#mobile-ide` `#on-device-ai` `#git` `#developer-tools` `#termux` `#gemini` `#slm` `#qwen` `#smollm` `#llama` `#offline-first` `#code-editor` `#live-preview`

---

## 🌟 Core Highlights

- 📱 **Phone-First Ergonomics:** Designed from the ground up for touchscreen development. Portrait-first workflow, quick developer symbol keyboard bar (`Tab`, `{`, `}`, `(`, `)`, `;`, `=>`, `"`, `$`), and one-thumb actions.
- 🤖 **Dual-Engine AI Architecture:** Seamlessly switch between **Cloud APIs** (Google Gemini 3.7 Flash, Gemini 3.1 Pro, OpenAI GPT-4o, Groq Llama 3.3 70B, OpenRouter, Anthropic) and **100% Private On-Device Mobile AI** (Qwen 2.5 Coder 0.5B/1.5B, SmolLM2 135M/1.7B, Llama 3.2 1B/3B, Phi-4 Mini, DeepSeek-R1-Distill) with instant offline fallback.
- 📷 **Visual Camera Debugger:** Real hardware camera preview with Google ML Kit on-device OCR text extraction and repository symbol matching.
- 🪐 **Interactive 3D Semantic Intel:** True 3D spatial spherical dependency graph with touch rotation, pitch/yaw orbit, perspective depth scaling, and single-tap blast radius & coupling risk telemetry.
- 🛠️ **8-Item Developer Workstation Tools:** Quick access to Run Project, Terminal, Git Status, Live Preview, Camera Error Debugger, Voice Coding Studio, Office Kit, and 3D Semantic Intel.
- ⚡ **Local In-App Dev Server & Live Preview:** Genuine loopback HTTP daemon listening on `127.0.0.1:5173`. Preview React, Vite, HTML, and FastAPI apps seamlessly inside the app or in mobile Chrome.
- 💻 **Real Developer Toolchains:** Execute `npm`, `node`, `vite`, `python`, `pip`, and `git` commands through Nivora's native execution engine.
- ❄️ **Declarative Nix & Multi-Stage Docker:** Full reproducible build and containerization configs (`default.nix`, `flake.nix`, `Dockerfile`, `docker-compose.yml`).
- 🎨 **Adaptive Dual-Theme Design System:** Complete luxury Dark Mode (`#090D16`) and crisp Light Mode (`#F8FAFC`) with dynamic theme toggling in onboarding, settings, and instant persistence.
- 🖥️ **Office Kit Wireless Companion:** Seamlessly bridges to a laptop for wide-screen mirroring, shared clipboard synchronization, and heavy build offloading when desired.

---

## 🔄 Core Workflow

```text
GitHub URL -> Clone -> Detect & Understand -> Repository Intelligence ->
Targeted AI Context Retrieval -> Propose Patch -> Review Diff (Keep / Discard) ->
Apply -> Local HTTP Dev Server -> Test -> Live Preview -> Git Diff -> Commit -> Push
```

---

## 🏗️ Architecture Overview

```text
┌─────────────────────────────────────────────────────────┐
│              Nivora Flutter UI Layer                    │
│   (Home, Editor, Terminal, Live Preview, AI Assistant)  │
├──────────────────────────┬──────────────────────────────┤
│  Repository Intelligence │     AI Agent & Tool Engine   │
│  - Scanner & AST Indexer │     - Surgical Retrieval     │
│  - Documentation Parser  │     - Patch & Diff Engine    │
├──────────────────────────┴──────────────────────────────┤
│            Nivora Local Runtime & Toolchains            │
│   - LocalDevServer (HTTP Daemon on loopback:5173)       │
│   - ProcessManager & Workstation Shell Engine           │
│   - Git Engine & File Sandbox                           │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.19.0`
- Android Studio / Android SDK (API 28+)
- Physical Android device or emulator

### Installation & Run

```bash
# Clone the repository
git clone https://github.com/om29dev/Nivora.git
cd Nivora

# Option A: Standard Flutter
flutter pub get
flutter analyze
flutter run

# Option B: Declarative Nix Shell
nix develop

# Option C: Multi-Stage Docker Container
docker compose up -d
```

---

## 📚 Technical Documentation

All detailed subsystem guides and architectural specifications are organized in the [**docs/**](file:///d:/proj/Nivora/docs/README.md) directory:

| Category | Document | Purpose |
|---|---|---|
| **Guidelines** | [**AGENTS.md**](file:///d:/proj/Nivora/AGENTS.md) | Engineering guidelines and non-negotiable rules for coding agents |
| **System** | [**ARCHITECTURE.md**](file:///d:/proj/Nivora/docs/ARCHITECTURE.md) | Full architectural blueprint and subsystem breakdown |
| **Decisions** | [**DECISIONS.md**](file:///d:/proj/Nivora/docs/DECISIONS.md) | Architectural Decision Records (ADRs 001–013) |
| **Intelligence** | [**AI_AGENT.md**](file:///d:/proj/Nivora/docs/AI_AGENT.md) | AI Agent specification, multi-session chat, and tool registry |
| **Intelligence** | [**REPOSITORY_INTELLIGENCE.md**](file:///d:/proj/Nivora/docs/REPOSITORY_INTELLIGENCE.md) | AST indexing, targeted budget retrieval & 3D blast radius analyzer |
| **Runtime** | [**RUNTIME.md**](file:///d:/proj/Nivora/docs/RUNTIME.md) | Local execution engine, loopback server, and toolchain support |
| **Console** | [**TERMINAL.md**](file:///d:/proj/Nivora/docs/TERMINAL.md) | Virtualized terminal console, PTY streaming, and command routing |
| **Design** | [**UI_GUIDELINES.md**](file:///d:/proj/Nivora/docs/UI_GUIDELINES.md) | Adaptive dual-theme design system, tokens, and component library |
| **Hardware** | [**OFFICE_KIT.md**](file:///d:/proj/Nivora/docs/OFFICE_KIT.md) | Companion desktop integration, screen mirroring, and clipboard sync |
| **Security** | [**SECURITY.md**](file:///d:/proj/Nivora/docs/SECURITY.md) | Mobile sandbox security, secret protection, and path validation |
| **Product** | [**TODO.md**](file:///d:/proj/Nivora/docs/TODO.md) | Project milestones and completed deliverables checklist |

Explore the full documentation hub at [**docs/README.md**](file:///d:/proj/Nivora/docs/README.md).
