# Nivora ⚡
> **AI-Native Mobile Development Workstation for Android**

Nivora turns your Android smartphone into a full-fledged local development environment. Clone, inspect, vibe-code, run, debug, test, and commit real GitHub repositories directly on your phone — without remote cloud servers, sluggish remote desktop sessions, or squished desktop IDE windows.

---

## 🌟 Core Highlights

- 📱 **Phone-First Ergonomics:** Designed from the ground up for touchscreen development. Portrait-first workflow, quick developer symbol keyboard bar (`Tab`, `{`, `}`, `(`, `)`, `;`, `=>`, `"`, `$`), and one-thumb actions.
- 🤖 **Repository-Aware AI Agent:** Indexes local source files, symbols, and documentation (`README.md`). Analyzes architecture, identifies bugs, proposes unified diffs, and feeds active editor buffers directly into ongoing chat sessions.
- ⚡ **Local In-App Dev Server & Live Preview:** Genuine loopback HTTP daemon listening on `127.0.0.1:5173`. Preview React, Vite, HTML, and FastAPI apps seamlessly inside the app or in mobile Chrome.
- 💻 **Real Developer Toolchains:** Execute `npm`, `node`, `vite`, `python`, `pip`, and `git` commands through Nivora's native execution engine.
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
- Android Studio / Android SDK (API 26+)
- Physical Android device or emulator

### Installation & Run
```bash
# Clone the repository
git clone https://github.com/om29dev/Nivora.git
cd Nivora

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Launch on connected Android device
flutter run
```

---

## 📚 Technical Documentation

| Document | Purpose |
|---|---|
| [**AGENTS.md**](file:///d:/proj/Nivora/AGENTS.md) | Engineering guidelines and non-negotiable rules for coding agents |
| [**ARCHITECTURE.md**](file:///d:/proj/Nivora/ARCHITECTURE.md) | Full architectural blueprint and subsystem breakdown |
| [**AI_AGENT.md**](file:///d:/proj/Nivora/AI_AGENT.md) | AI Agent specification, multi-session chat, and tool registry |
| [**RUNTIME.md**](file:///d:/proj/Nivora/RUNTIME.md) | Local execution engine, loopback server, and toolchain support |
| [**TERMINAL.md**](file:///d:/proj/Nivora/TERMINAL.md) | Virtualized terminal console, PTY streaming, and command routing |
| [**UI_GUIDELINES.md**](file:///d:/proj/Nivora/UI_GUIDELINES.md) | Design system, theme tokens, and mobile component library |
| [**OFFICE_KIT.md**](file:///d:/proj/Nivora/OFFICE_KIT.md) | Companion desktop integration, screen mirroring, and clipboard sync |
| [**DECISIONS.md**](file:///d:/proj/Nivora/DECISIONS.md) | Architectural Decision Records (ADRs) |
| [**TODO.md**](file:///d:/proj/Nivora/TODO.md) | Project milestones and completed feature list |

---

## 📄 License
Licensed under the Apache License, Version 2.0.
