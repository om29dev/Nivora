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

---

## ADR 008: Embedded Termux Runtime Without Standalone Termux App
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Users require real Linux developer toolchains (`pkg`, `apt`, `nodejs`, `python`, `git`, `bash`) on mobile without forcing the installation of the standalone Termux application or requiring root permissions.
- **Decision:** Embed a self-contained Termux runtime management engine (`TermuxEnvironmentService`) that downloads architecture-matched official Termux bootstraps into Nivora's sandbox, parses `SYMLINKS.txt`, sets executable bits, and uses user-space PRoot path mapping (`-b <prefix>:/data/data/com.termux/files/usr`). Dispatches real processes on desktop environments.
- **Alternatives Considered:** Requiring external Termux app via Android intents (breaks seamless UX, poor integration), mocking command outputs (violates rule 5, non-functional tools).
- **Consequences:** The terminal inside Nivora functions like Termux, installs and executes genuine Termux packages, works out-of-the-box offline or on-demand, and keeps code execution isolated in the app sandbox.

---

## ADR 009: Global Bottom Navigation with Floating Center AI Button
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Mobile developers need quick, thumb-ergonomic switching between Dashboard, Terminal, Semantic Intel, and auxiliary tools, with the AI Agent acting as the primary elevated centerpiece rather than a generic fifth tab.
- **Decision:** Implement a floating pill navigation container (`NivoraBottomNavBar`) using GoRouter `StatefulShellRoute.indexedStack` with 4 symmetrical destinations (`Dashboard`, `Terminal`, `Intel`, `More`), and a 66dp circular AI floating button (`NivoraFloatingAIButton`) rising 22dp above the bar edge with concentric halo glow and tactile spring animation.
- **Alternatives Considered:** Standard Material BottomNavigationBar (lacks luxury floating pill styling, cannot overlap center action), generic fifth navigation tab for AI (diminishes AI prominence as the primary development agent).
- **Consequences:** Instant tab switching with zero state loss for terminal streams or project context; prominent, elegant visual hierarchy where AI is the core companion.

---

## ADR 010: Interactive 3D Spatial Spherical Graph for Semantic Intel
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Visualizing complex codebase coupling and blast radius impact in flat 2D concentric rings leads to node overlap and poor spatial comprehension on mobile screens.
- **Decision:** Implement a pure Dart CustomPainter 3D spatial spherical graph (`BlastRadiusCanvas`) with camera pitch, yaw, zoom, auto-orbit, perspective depth scaling, and Z-buffer depth sorting, coupled with interactive touch hit-testing to inspect cascading blast radius telemetry for any node.
- **Alternatives Considered:** Heavy third-party 3D engine packages (large binary overhead, poor battery performance).
- **Consequences:** Ultra-smooth 60fps 3D rendering with zero external dependencies, tactile spatial rotation, and clear node blast radius inspection.

---

## ADR 011: Dual Cloud vs Local On-Device AI Architecture
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Users require both powerful cloud LLM capabilities (Gemini, OpenAI, Groq, OpenRouter) and 100% private offline on-device inference (HuggingFace GGUF models, Ollama, Termux llama-server).
- **Decision:** Implement a unified `AIConfig` and `RealAIProvider` architecture featuring segmented mode selection, provider/model dropdown catalogs, live latency pings, per-provider persistent API key storage, and seamless fallback to the on-device Nano-LLM engine when offline or without keys.
- **Alternatives Considered:** Cloud-only (no offline support) or local-only (constrained reasoning on low-spec phones).
- **Consequences:** Complete user flexibility, reliable offline developer intelligence, zero downtime, and instant configuration.

---

## ADR 012: Declarative Nix & Multi-Stage Docker Toolchains
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Contributors and CI/CD pipelines need a fully reproducible development environment without version drift across Flutter, Android SDK 34, JDK 17, Node 20, Python 3.11, and Ollama.
- **Decision:** Provide declarative Nix flakes (`default.nix`, `flake.nix`) and a multi-stage `Dockerfile` with `docker-compose.yml` orchestrating the development workstation and on-device Ollama inference services.
- **Alternatives Considered:** Manual installation instructions (error-prone, platform inconsistencies).
- **Consequences:** Instant one-command reproducibility (`nix develop` or `docker compose up`) with isolated caching for pub and Gradle dependencies.

---

## ADR 013: Real Hardware Camera with On-Device Google ML Kit Text Recognition
- **Date:** 2026-09-01
- **Status:** Accepted
- **Context:** Developers debugging errors on external monitors or terminal windows need real-time OCR text capture to feed compiler error logs directly to the AI agent.
- **Decision:** Integrate the official `camera` plugin with live `CameraPreview`, camera flip selection, device gallery picker, and on-device Google ML Kit OCR (`google_mlkit_text_recognition`) with AST symbol cross-referencing.
- **Alternatives Considered:** Cloud OCR APIs (requires internet, adds latency, potential privacy leak for private code on monitors).
- **Consequences:** Instant on-device visual error diagnosis with zero latency, zero cloud dependency, and automatic repository file matching.
