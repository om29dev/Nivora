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
- [x] Build `GitService` (clone, status, diff, add, commit, branch, push, pull).
- [x] Build `AIAgentEngine` with `ToolRegistry` and `PatchEngine`.
- [x] Build `OfficeKitService` and `StorageService`.

## 4. Screens & User Workflows
- [x] Splash (`/`) & 3-step Onboarding (`/onboarding`) with live theme switcher.
- [x] AI Setup screen (`/ai-setup`) with local vs external provider selection.
- [x] Home screen (`/home`) with GitHub URL cloner bar and seeded demo repositories.
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
- [x] Global Bottom Navigation System (`NivoraNavShell`, `NivoraBottomNavBar`):
  - [x] Tab 0: Dashboard (`/home`) with greeting, GitHub URL cloner, and recent projects.
  - [x] Tab 1: Dedicated Projects Explorer (`/projects`) with live search filter and repository cards.
  - [x] Tab 2: Workstation Terminal (`/terminal`) connecting to real process streams & Termux runtime.
  - [x] Tab 3: More Tools Hub (`/more`) for Runner, Git, Camera, Voice, Office Kit, and Settings.
  - [x] Overlapping Center Floating AI Button (`NivoraFloatingAIButton`) rising 22dp with tactile glow.
  - [x] GoRouter `StatefulShellRoute.indexedStack` preserving state across all tabs.
- [x] Runner & Live Preview with Chrome launch fallback (`/project/:id/run`).
- [x] Git Source Control (`/project/:id/git`).
- [x] Voice Coding modal (`/voice-coding`).
- [x] Office Kit wireless companion screen (`/office-kit`).
- [x] Settings screen (`/settings`) with embedded Termux management card and permission toggles.

## 5. Verification & Quality
- [x] Run `flutter analyze` — 0 issues found.
- [x] Run `flutter test` — all 18 unit & widget tests passing (18/18).
- [x] Unit tests for navigation & AI button (`test/unit/navigation_test.dart`).
- [x] Unit tests for TermuxEnvironmentService (`test/unit/termux_service_test.dart`).
- [x] End-to-end verified on physical Android device.
