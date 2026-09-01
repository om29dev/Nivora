# AGENTS.md — Nivora Engineering Guidelines & Rules for Coding Agents

## 1. Project Mission
Nivora is a **phone-first local development environment for Android** enabling developers to clone, understand, vibe-code, run, debug, test, and commit real GitHub repositories directly on their smartphone.

The core workflow is:
```text
GitHub URL -> Clone -> Detect & Understand -> Repository Intelligence ->
Targeted AI Context Retrieval -> Propose Patch -> Review Diff -> Apply ->
Local Run -> Test -> Camera/Voice Debug -> Live Preview -> Git Diff -> Commit -> Push
```

Nivora is **NOT** a chatbot, a generic code editor, a remote IDE, or a desktop IDE squished onto a mobile screen. It is an **AI-native mobile development workstation**.

---

## 2. Architecture Rules
- **Flutter** is the primary UI and orchestration layer.
- **Native Android / Platform Bridges / Native Processes** handle:
  - Linux/runtime execution (Node.js, Python, Shell, Git)
  - Process management and streaming terminal pipes
  - Camera, OCR, audio recording & speech-to-text
  - File system operations & isolated sandboxing
  - Office Kit connectivity protocols
- Keep layers strictly decoupled: UI never interacts directly with low-level platform APIs without going through abstract services and Riverpod providers.

---

## 3. Flutter & Dart Quality Rules
- Dart null-safety is mandatory everywhere.
- Strictly adhere to `flutter_lints`.
- No business logic inside widgets. Widgets only render state and dispatch events.
- Heavy computations (file scanning, AST/symbol parsing, diff computation) MUST run in background Dart `compute` / isolates, never on the UI isolate.
- Use `flutter_riverpod` for all state management.
- Centralize design system tokens (colors, typography, spacing, elevations).
- UI is strictly mobile-first: portrait primary with natural touch ergonomics, landscape optimized for dual-pane views.

---

## 4. AI & Agent Rules
- **Local AI first:** Prioritize local, private, on-device or local-network models. External AI is strictly an opt-in fallback.
- **Targeted Context Retrieval:** NEVER feed the entire repository tree to an LLM. Always select only relevant files, extracted symbols, and Markdown documentation within a strict context budget.
- **Controlled Tool Calling:** Agents operate through strictly defined, deterministic tools (`search_code`, `read_file`, `apply_patch`, `run_command`, etc.).
- **Human-in-the-loop Guardrails:** Destructive operations (file deletion, `rm`, package installs, git force checkout, git push) REQUIRE explicit user confirmation.
- **No Hidden Chain-of-Thought:** Never expose raw internal reasoning or messy prompts. Display crisp, user-friendly agent status steps (e.g. `Searching project documentation... ✓`).

---

## 5. Runtime & Execution Rules
- Real tools only: Provide genuine execution for Node.js (`node`, `npm`, `npx`), Python (`python`, `python3`, `pip`), Git (`git`), and shell utilities.
- Never fake command outputs or terminal responses.
- Isolate execution to the active project's root directory.

---

## 6. Security Rules
- Cloned repositories must be treated as untrusted code.
- Prevent path traversal (`../`) outside the project sandbox.
- Protect secrets: Never send `.env`, credentials, SSH keys, or access tokens to AI prompts.
- Never auto-push commits to remote repositories without explicit user action.

---

## 7. Definition of Done
A feature is **NOT** done merely because its UI screen exists.
- Real backend functionality and data flow must work.
- Unit and widget tests must pass.
- Architecture and documentation files must be updated.
