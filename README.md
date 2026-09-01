# Nivora ⚡
> **AI-Native Mobile Development Workstation for Android**

Nivora turns your Android smartphone into a full-fledged local development environment. Clone, inspect, vibe-code, run, debug, test, and commit real GitHub repositories directly on your phone — without remote cloud servers, sluggish remote desktop sessions, or squished desktop IDE windows.

---

## 🌟 Core Highlights

- 📱 **Phone-First Ergonomics:** Designed from the ground up for touchscreen development. Portrait-first workflow, quick developer symbol keyboard bar (`Tab`, `{`, `}`, `(`, `)`, `;`, `=>`, `"`, `$`), and one-thumb actions.
- 🤖 **Dual-Engine AI Architecture:** Seamlessly switch between **Cloud APIs** (Gemini 2.0 Flash, OpenAI GPT-4o, Groq Llama 3.3 70B, OpenRouter, Anthropic) and **100% Private On-Device AI** (HuggingFace GGUF models like SmolLM2, Qwen2.5-Coder, TinyLlama, and Ollama) with instant offline fallback.
- 🪐 **Interactive 3D Semantic Intel:** True 3D spatial spherical dependency graph with touch rotation, pitch/yaw orbit, perspective depth scaling, and single-tap blast radius & coupling risk telemetry.
- 🛠️ **8-Item Developer Workstation Tools:** Quick access to Run Project, Terminal, Git Status, Live Preview, Camera Error Debugger, Voice Coding Studio, Office Kit, and 3D Semantic Intel.
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

All detailed subsystem guides and architectural specifications are organized in the [**docs/**](file:///d:/proj/Nivora/docs/README.md) directory:

| Category | Document | Purpose |
|---|---|---|
| **Guidelines** | [**AGENTS.md**](file:///d:/proj/Nivora/AGENTS.md) | Engineering guidelines and non-negotiable rules for coding agents |
| **System** | [**ARCHITECTURE.md**](file:///d:/proj/Nivora/docs/ARCHITECTURE.md) | Full architectural blueprint and subsystem breakdown |
| **Decisions** | [**DECISIONS.md**](file:///d:/proj/Nivora/docs/DECISIONS.md) | Architectural Decision Records (ADRs 001–011) |
| **Intelligence** | [**AI_AGENT.md**](file:///d:/proj/Nivora/docs/AI_AGENT.md) | AI Agent specification, multi-session chat, and tool registry |
| **Intelligence** | [**REPOSITORY_INTELLIGENCE.md**](file:///d:/proj/Nivora/docs/REPOSITORY_INTELLIGENCE.md) | AST indexing, targeted budget retrieval & 3D blast radius analyzer |
| **Runtime** | [**RUNTIME.md**](file:///d:/proj/Nivora/docs/RUNTIME.md) | Local execution engine, loopback server, and toolchain support |
| **Console** | [**TERMINAL.md**](file:///d:/proj/Nivora/docs/TERMINAL.md) | Virtualized terminal console, PTY streaming, and command routing |
| **Design** | [**UI_GUIDELINES.md**](file:///d:/proj/Nivora/docs/UI_GUIDELINES.md) | Adaptive dual-theme design system, tokens, and component library |
| **Hardware** | [**OFFICE_KIT.md**](file:///d:/proj/Nivora/docs/OFFICE_KIT.md) | Companion desktop integration, screen mirroring, and clipboard sync |
| **Security** | [**SECURITY.md**](file:///d:/proj/Nivora/docs/SECURITY.md) | Mobile sandbox security, secret protection, and path validation |
| **Product** | [**TODO.md**](file:///d:/proj/Nivora/docs/TODO.md) | Project milestones and completed deliverables checklist |

Explore the full documentation hub at [**docs/README.md**](file:///d:/proj/Nivora/docs/README.md).

---

## 📄 License
Licensed under the Apache License, Version 2.0.
