# ARCHITECTURE.md — Nivora System & Software Architecture

## 1. High-Level Architectural Diagram

```text
                                 NIVORA
                                   │
                           ┌───────▼────────┐
                           │   Flutter UI   │
                           └───────┬────────┘
                                   │
                         Application Layer (Riverpod)
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
 Repository Intelligence       AI Agent Engine        Workspace & Runtime
        │                          │                          │
  ┌─────┴───────┐           ┌──────┴───────┐           ┌──────┴───────┐
  │ Scanner     │           │ Context Eng  │           │ Process Mgr  │
  │ Manifests   │           │ Tool Registry│           │ Term Buffer  │
  │ Doc Analyzer│           │ Prompt Eng   │           │ Port Watcher │
  │ Symbol Index│           │ Model Client │           │ Git Service  │
  └─────────────┘           └──────────────┘           └──────────────┘
        │                          │                          │
        └──────────────────────────┼──────────────────────────┘
                                   │
                            Platform Bridge
                                   │
             ┌─────────────────────┼─────────────────────┐
             │                     │                     │
             ▼                     ▼                     ▼
       Android APIs         Runtime Engine        Storage & Cache
    (Camera, Audio,       (Node, Python, Git,   (SQLite, File Sandbox,
      Office Kit)               Shell)                Pref Store)
```

---

## 2. Layer Definitions

### 1. Presentation Layer (Flutter UI)
- Built with Flutter + Dart.
- Follows the Atomic Design inspired component library (`Nivora*` widgets).
- Zero direct IO calls; interacts solely through Riverpod Notifiers and Providers.
- Strict 60/120fps UI render loop without UI isolate blocking.

### 2. State & Application Layer
- Managed via `flutter_riverpod`.
- Domain-isolated state notifiers:
  - `projectsProvider`: tracks active and recent repositories.
  - `repositoryIntelligenceProvider`: manages indexing, symbols, and docs.
  - `editorProvider`: handles active document buffer, dirty status, syntax.
  - `aiAgentProvider`: coordinates tool calling, context retrieval, and diff generation.
  - `terminalProvider`: manages virtual scrollback lines, running process streams, ANSI parsing.
  - `gitProvider`: exposes git status, diffs, branches, and commits.
  - `runtimeProvider`: reports toolchain health (Node, Python, Git).
  - `hardwareProvider`: bridges camera, audio speech recognition, and Office Kit sync.

### 3. Repository Intelligence Engine
- **Scanner:** Traverses project directory while excluding ignored trees (`node_modules`, `.git`, `dist`, `build`, `__pycache__`).
- **Manifest Parser:** Inspects `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc.
- **Markdown Extractor:** Parses `README.md` and `docs/` using structured section heuristics to capture project goals, dev commands, and architecture.
- **Symbol Indexer:** Extracts class, function, component, and route declarations with line references.
- **Context Retriever:** Ranks and selects a compact context window (< 4,000 tokens) tailored to the prompt.

### 4. AI Agent & Tool Execution
- Multi-provider client abstraction:
  - `LocalModelProvider`: Runs local models or connects to local on-device inference endpoints.
  - `ExternalModelProvider`: Connects to external OpenAI-compatible or Anthropic APIs.
- Tool registry: Deterministic tools with schema validation (`search_code`, `search_docs`, `read_file`, `apply_patch`, `run_command`).
- Confirmation gatekeeper: Inspects tool actions and flags destructive operations for user review.

### 5. Runtime & Process Engine
- Interfaces with local toolchains via `ProcessManager` and Workstation Shell Engine, intercepting `npm`, `node`, `git`, `python`, `vite` commands to bypass Android `/system/bin/sh` code 127 restrictions.
- In-app `LocalDevServer` HTTP daemon bound to `127.0.0.1:5173` serving SPAs, static assets, and mock REST APIs directly to mobile Chrome and in-app WebView.
- Virtualized terminal scrollback buffer with line cap (2,000 lines) and ANSI color parsing.
- Process lifecycle management (PID tracking, background daemons, port listeners, SIGINT/SIGKILL).

### 6. Storage & Sandboxing
- Projects stored under isolated directory: `Nivora/projects/<repo_name>/`.
- Caches and indices stored under: `Nivora/indexes/<repo_name>/`.
- Sandboxing checks prevent paths from resolving outside the project's root.
