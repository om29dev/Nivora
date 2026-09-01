# TODO.md — Nivora Engineering Tasks & Action Items

## 1. Project Scaffolding
- [x] Initialize Flutter app with package name `com.nivora.app` in `d:\proj\Nivora`.
- [x] Configure `pubspec.yaml` with required dependencies (`flutter_riverpod`, `go_router`, `google_fonts`, `shared_preferences`, `path_provider`, `path`, `crypto`, `intl`).
- [x] Create clean scalable architecture (`lib/app/`, `lib/core/`, `lib/features/`).

## 2. Design System & Theme Engine
- [x] Implement `AppTheme`, `AppColors`, and `AppTypography` with luxury dark-first tokens.
- [x] Implement comprehensive Light Theme system with high-contrast slate surfaces and text tokens.
- [x] Build context-aware adaptive color getters (`AppColors.text(context)`, `AppColors.surface(context)`).
- [x] Add theme toggle to Onboarding screen header and Settings screen with instant state persistence.
- [x] Implement full `Nivora*` component suite (`NivoraButton`, `NivoraCard`, `NivoraChip`, `NivoraInput`, `NivoraAppBar`, `NivoraBottomSheet`, `NivoraDialog`, `NivoraStatus`, `NivoraProgress`, `NivoraProjectCard`, `NivoraFileRow`, `NivoraCodeHeader`, `NivoraTerminalLineWidget`, `NivoraAIMessage`, `NivoraAgentStepWidget`, `NivoraDiffViewer`, `NivoraEmptyState`, `NivoraErrorState`).

## 3. Core Subsystems & Runtime Engine
- [x] Build `RepositoryScanner`, `ProjectDetector`, `MarkdownAnalyzer`, `SymbolIndexer`, and `ContextRetriever`.
- [x] Build `LocalDevServer` HTTP daemon bound to `InternetAddress.loopbackIPv4` on port `5173`.
- [x] Build `ProcessManager` with genuine real process execution engine (replacing all mocked responses).
- [x] Build `TermuxEnvironmentService` providing self-contained embedded Termux runtime without requiring the standalone Termux app:
  - Architecture detection (`aarch64`, `arm`, `x86_64`).
  - Bootstrap download & extraction from official Termux releases.
  - `SYMLINKS.txt` parsing and permissions setup.
  - User-space PRoot path mapping (`/data/data/com.termux/files/usr`).
  - Support for `pkg install` / `apt install` (nodejs, python, git, etc.).
- [x] Declarative Nix environment (`default.nix`, `flake.nix`) for reproducible toolchains (Flutter, Android SDK 34, JDK 17, Node 20, Python 3.11).
- [x] Multi-stage Docker workstation (`Dockerfile`, `docker-compose.yml`) bundling Flutter, Android SDK, and Ollama inference daemon.
- [x] Build `GitService` (clone, status, diff, add, commit, branch, push, pull).
- [x] Build `AIAgentEngine` with `ToolRegistry` and `PatchEngine`.
- [x] Build `OfficeKitService` and `StorageService`.

## 4. Screens & User Workflows
- [x] Splash (`/`) & 3-step Onboarding (`/onboarding`) with live theme switcher and official Nivora branding.
- [x] AI Setup screen (`/ai-setup`) with dual **Cloud API** (Gemini, OpenAI, Groq, OpenRouter, Anthropic) vs **Local On-Device AI** (HuggingFace GGUF, Ollama, llama-server) architecture selectors, model dropdowns, and **real live round-trip HTTP latency testing (ms)**.
- [x] Home screen (`/home`):
  - [x] GitHub URL cloner bar and seeded demo repositories.
  - [x] Frosted glass telemetry ribbon (Sandboxes, AI Engine, AST Intel).
  - [x] AI Copilot & Clone Repository tabbed glass hub with quick suggestion chips.
  - [x] 8-item Workstation Tools Grid (Run Project, Terminal, Git Status, Live Preview, Camera Debug, Voice Studio, Office Kit, 3D Intel).
  - [x] Polished frosted AppBar with subtle bottom border.
- [x] Clone progress modal (`/clone`) with staged progress steps.
- [x] Project Overview & Intelligence view (`/project/:id`).
- [x] File Explorer (`/project/:id/files`).
- [x] Code Editor with developer keyboard bar and live file scanner (`/project/:id/editor`).
- [x] AI Assistant (`/project/:id/ai`):
  - [x] Repository-level documentation scan and actionable recommendations on project open.
  - [x] In-editor code scanner feeding into active continued chat.
  - [x] Multi-session chat history with previous session switching.
  - [x] New chat creation button.
  - [x] User message editing and re-prompting.
  - [x] Bounded diff review sheet with **Keep & Apply** and **Discard** actions.
  - [x] Auto-dismissing Agent Execution Pipeline (smoothly disappears after 2 seconds upon task completion/failure).
  - [x] Seamless fallback to on-device Nano-LLM engine when offline or when no API key is set.
- [x] Semantic Intel & Blast Radius Analyzer (`/semantic-intel`):
  - [x] Real AST repository file and symbol mapping.
  - [x] Interactive 3D Spatial Spherical Graph Canvas with pitch, yaw, zoom, auto-orbit, and Z-buffer depth scaling.
  - [x] Interactive 3D node touch hit-testing to inspect blast radius, coupling risk %, and cascading impact.
- [x] Global Bottom Navigation System (`NivoraNavShell`, `NivoraBottomNavBar`):
  - [x] Tab 0: Dashboard (`/home`).
  - [x] Tab 1: Workstation Terminal (`/terminal`).
  - [x] Tab 2: Semantic Intel (`/semantic-intel`).
  - [x] Tab 3: More Tools Hub (`/more`).
  - [x] Overlapping Center Floating AI Button (`NivoraFloatingAIButton`) with tactile glow.
  - [x] GoRouter `StatefulShellRoute.indexedStack` preserving state across all tabs.
- [x] Visual Camera Debugger (`/camera-debug`) with real hardware camera feed, switch lens, Google ML Kit on-device OCR, and gallery picker.
- [x] Voice Coding Studio (`/voice-coding`) with speech-to-intent dictation.
- [x] Office Kit wireless companion (`/office-kit`) for screen mirroring and clipboard sync.
- [x] Settings screen (`/settings`) with embedded Termux management card and permission toggles.

## 5. Verification & Quality
- [x] Android app launcher icons generated across all mipmap densities (`mipmap-mdpi`, `mipmap-hdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`) using official Nivora branding.
- [x] Run `flutter analyze --no-pub` — 0 issues found (100% clean).
- [x] Run `flutter test` — all 35 unit & widget tests passing (35/35).
- [x] Unit tests for intelligence, Nano-LLM, real AI provider live connection ping, navigation, runner preview, terminal buffer, and smoke tests.
