# ROADMAP.md — Nivora Engineering Roadmap & Milestone Tracking

## Milestones Status

### Milestone 1: Specifications & Architectural Memory
- [x] Create all 16 engineering memory markdown files.
- [x] Define architectural layers, contracts, and security rules.

### Milestone 2: Flutter Scaffolding & Design System
- [x] Initialize Flutter project (`com.nivora.app`).
- [x] Configure `pubspec.yaml` with Riverpod, GoRouter, GoogleFonts, PathProvider, SharedPreferences, Crypto.
- [x] Implement dark-first design system (`AppTheme`, `AppColors`, `AppTypography`).
- [x] Implement full `Nivora*` component suite:
  - `NivoraButton`, `NivoraSecondaryButton`, `NivoraCard`, `NivoraChip`, `NivoraInput`
  - `NivoraAppBar`, `NivoraBottomSheet`, `NivoraDialog`, `NivoraStatus`, `NivoraProgress`
  - `NivoraProjectCard`, `NivoraFileRow`, `NivoraCodeHeader`, `NivoraTerminalLineWidget`
  - `NivoraAIMessage`, `NivoraAgentStepWidget`, `NivoraDiffViewer`, `NivoraEmptyState`, `NivoraErrorState`

### Milestone 3: Repository Intelligence & Context Engine
- [x] Implement `RepositoryScanner` (recursive directory scan with ignore rules for `node_modules`, `.git`, `dist`, binaries).
- [x] Implement `ProjectDetector` (manifest recognition for Node.js, Python, Rust, Go, Flutter, Make).
- [x] Implement `MarkdownAnalyzer` (documentation semantic extraction from `README.md`, docs, commands, env vars).
- [x] Implement `SymbolIndexer` (regex/AST symbol mapping for classes, functions, components, routes, exports).
- [x] Implement `TargetedContextRetriever` (context budgeting & ranking capped at 3,800 tokens).

### Milestone 4: Runtime & Terminal Subsystem
- [x] Build `RuntimeManager` (probe Node, npm, Python, pip, Git, shell toolchains).
- [x] Build `ProcessManager` (real process execution, PID management, port detection on 5173/3000/8000).
- [x] Build `AnsiParser` and terminal scrollback buffer capped at 2,000 lines.

### Milestone 5: AI Agent Engine & Tool Execution
- [x] Implement `AIProvider` contract with `LocalAIProvider` and `ExternalAIProvider`.
- [x] Build `ToolRegistry` (`search_code`, `read_file`, `get_git_status`, `get_git_diff`, `run_command`).
- [x] Build `PatchEngine` with unified line diff generation and file patch application.
- [x] Implement human-in-the-loop diff confirmation workflow.

### Milestone 6: Complete Screen Catalog
- [x] Splash screen (`/`) with brand animation and cold start.
- [x] 3-step Onboarding screen (`/onboarding`) with persistent completion.
- [x] AI Setup screen (`/ai-setup`) with On-Device AI default.
- [x] Home screen (`/home`) with GitHub URL cloner bar and recent projects (No generic "New Project" button!).
- [x] Clone progress modal (`/clone`) with staged verified progress steps.
- [x] Project Overview & Intelligence view (`/project/:id`).
- [x] File Explorer (`/project/:id/files`) with search and Git status badges.
- [x] Mobile Code Editor (`/project/:id/editor`) with virtual keyboard accessory bar (`{`, `}`, `(`, `)`, `;`, `=>`, `Tab`).
- [x] AI Assistant (`/project/:id/ai`) with agentic step progression and Diff Review sheet.
- [x] Interactive Terminal (`/project/:id/terminal`) with shortcuts, Ctrl+C kill, copy, clear.
- [x] Runner & Live Preview (`/project/:id/run`) with server controls, URL bar, logs.
- [x] Git Source Control (`/project/:id/git`) with changes list, diff viewer, commit, and push guardrails.
- [x] Camera Debugger (`/camera-debug`) with viewfinder, OCR error extraction, and "Fix with AI".
- [x] Voice Coding modal (`/voice-coding`) with pulsing audio listener and intent routing.
- [x] Office Kit screen (`/office-kit`) with phone-to-laptop connectivity and compute split architecture.
- [x] Global Settings screen (`/settings`) with toolchain status and AI safety permissions.

### Milestone 7: Verification & Automated Tests
- [x] Unit tests for intelligence engine, symbol indexer, and context retriever (`test/unit/intelligence_test.dart`).
- [x] Unit tests for patch engine and diff generator (`test/unit/patch_engine_test.dart`).
- [x] Unit tests for terminal buffer bounds and ANSI parser (`test/unit/terminal_buffer_test.dart`).
- [x] Smoke and widget tests for application startup (`test/widget_test.dart`).
- [x] Zero analyzer issues (`flutter analyze`).
- [x] All automated tests passing (`flutter test`).
