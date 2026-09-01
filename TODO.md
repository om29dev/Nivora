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
- [x] Build `ProcessManager` with Workstation Shell Engine routing for developer commands (`npm`, `node`, `vite`, `git`, `python`).
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
- [x] Terminal view with streaming scrollback and port detection (`/project/:id/terminal`).
- [x] Runner & Live Preview with Chrome launch fallback (`/project/:id/run`).
- [x] Git Source Control (`/project/:id/git`).
- [x] Voice Coding modal (`/voice-coding`).
- [x] Office Kit wireless companion screen (`/office-kit`).
- [x] Settings screen (`/settings`) with working interactive permission toggles.

## 5. Verification & Quality
- [x] Run `dart analyze lib` — 0 issues found.
- [x] Run `flutter test` — all unit & widget tests passing (8/8).
- [x] End-to-end verified on physical Android device.
