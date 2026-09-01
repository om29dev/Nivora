# DECISIONS.md — Nivora Architectural Decision Records (ADRs)

## ADR 001: Primary Application Framework — Flutter + Dart
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Need a fast, beautiful, phone-first UI that renders at 60/120fps with native access to hardware and process execution.
- **Decision:** Use Flutter with Dart null safety as the primary UI and orchestration layer.
- **Alternatives Considered:** React Native (slower JS bridge), Jetpack Compose (Android only, harder multi-device support), Web in WebView (poor touch latency).
- **Consequences:** Superb rendering performance and unified design language; native platform functionality handled via clean platform bridges and services.

---

## ADR 002: State Management — Flutter Riverpod
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Complex application with multiple concurrent subsystems (AI agent steps, process stdout streaming, file tree changes, git status, editor buffer).
- **Decision:** Use `flutter_riverpod` for declarative, compile-safe dependency injection and state handling.
- **Alternatives Considered:** Bloc (boilerplate heavy), Provider (lacks modern scoping), GetX (untyped, anti-pattern).
- **Consequences:** Predictable state transitions, isolated domains, and testable providers.

---

## ADR 003: Targeted Retrieval Over Raw Codebase Dumping
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Mobile phones have memory and compute constraints. Local LLMs have small context windows (typically 2k-8k tokens).
- **Decision:** Implement a 2-stage retrieval pipeline (Documentation summary + Symbol & path ranking) to cap prompt context at under 4,000 tokens.
- **Alternatives Considered:** Dumping the whole repository tree into the prompt.
- **Consequences:** Vastly faster local inference, higher patch accuracy, and zero token waste.

---

## ADR 004: In-App Loopback HTTP Server Daemon (`LocalDevServer`)
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Running web applications on Android requires real browser verification in mobile Chrome without external tunneling or cloud relays.
- **Decision:** Embed a native Dart `HttpServer` listening on `InternetAddress.loopbackIPv4` (`127.0.0.1`) on port `5173`. Serves project files, Vite/React SPA index routing, and mock REST endpoints directly to mobile browsers.
- **Alternatives Considered:** Cloudflare tunnels / ngrok (requires internet connection, slow), Android asset loaders (doesn't support real HTTP networking).
- **Consequences:** Chrome opens `http://localhost:5173` offline on the phone with zero setup and instant reload.

---

## ADR 005: Android Developer Toolchain Command Interception
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Standard Android `/system/bin/sh` lacks developer tools (`npm`, `git`, `python`, `vite`), returning exit code `127: inaccessible or not found`.
- **Decision:** Implement a Workstation Shell Engine inside `ProcessManager` that intercepts developer commands and executes genuine operations or routes to local engines.
- **Alternatives Considered:** Bundling full Termux debian packages (huge 2GB+ APK size).
- **Consequences:** Developer commands run out of the box in the terminal and quick-run buttons without requiring root or external packages.

---

## ADR 006: Adaptive Dual-Theme System (Dark & Light)
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Developers code in varying lighting conditions; relying solely on dark mode causes glare or preference friction.
- **Decision:** Implement a centralized semantic token system in `AppColors` and `AppTypography` with context-aware theme getters (`AppColors.text(context)`, `AppColors.surface(context)`) and persistent switching.
- **Alternatives Considered:** Hardcoded colors or separate duplicate widgets for light and dark.
- **Consequences:** Clean visual consistency across all 15+ screens, zero white-on-white text bugs, and one-tap toggling in onboarding and settings.

---

## ADR 007: Continued Multi-Session AI Chat with In-Editor File Scanner
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Developers alternate between high-level architectural exploration and file-specific refactoring.
- **Decision:** Separate repository-level scans (triggered via "Ask AI" in project overview) from file-level feeding (triggered via the in-editor scanner button into the active continued chat session). Added multi-session history, prompt editing, and bounded Keep / Discard diff review.
- **Alternatives Considered:** Ephemeral single-turn modals with no chat memory.
- **Consequences:** Natural pair-programming workflow where file context flows directly into conversation memory without losing previous exchanges.
