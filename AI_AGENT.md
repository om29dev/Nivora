# AI_AGENT.md — Nivora AI Agent Architecture & Tool Specifications

## 1. Agent Design Philosophy
The Nivora AI Agent is an autonomous, repository-aware software engineering agent running directly against local repository files on mobile hardware.

Key principles:
1. **Never dump the full codebase:** The agent operates strictly on surgical context retrieved by the Repository Intelligence engine (under 4,000 tokens).
2. **Controlled tool calling:** Every read or mutation occurs via explicit, deterministic tool interfaces.
3. **No hidden chain-of-thought:** The user sees crisp, real-time action steps (`Searching documentation... ✓`, `Patching src/App.tsx... ✓`).
4. **Diff-first modification with Keep / Discard:** The agent never silently mutates code on disk. It produces a unified diff reviewable in a non-overflowing sheet where the user explicitly chooses to **Keep & Apply** or **Discard**.
5. **Continuous Conversation & Multi-Session History:** Conversations are persisted in distinct chat sessions with the ability to switch between previous chats, start fresh chats, or edit prior prompts.

---

## 2. Conversation & Ingestion Workflows

### A. Repository-Level "Ask AI" (Project Overview)
When the user taps "Ask AI" from the Project Overview screen, the agent performs a high-level scan of the project's documentation (`README.md`), configuration files, and symbol registry:
- **Detected Stack:** Runtime, framework, and language summary.
- **Index Metrics:** Count of mapped symbols and indexed source files.
- **Actionable Recommendations:** Suggests 3 high-impact enhancements (e.g. dark mode state persistence, offline mock fallback, component caching) that can be triggered with one tap.

### B. In-Editor "Scan & Feed" into Continued Chat
When working in the Code Editor:
- Tapping the **Scan** action (`Icons.document_scanner_rounded`) captures the current file's relative path (e.g., `src/App.tsx`) and live buffer.
- The file is injected directly into the **active continued chat session** as an attached code snippet.
- The agent inspects the code for bugs, logic flaws, or performance issues, and proposes focused diffs within the ongoing conversation.

### C. Multi-Session History & Prompt Editing
- **Session Management (`ChatSession`):** Supports multiple named chat sessions with message history and timestamps.
- **Chat History Drawer:** View and switch between past conversations anytime.
- **New Chat Creation:** Start a fresh conversation with one tap while retaining past sessions.
- **Edit Previous Messages:** Every user message features an edit action (`Icons.edit_outlined`) to reload the prompt back into the input field for quick refinement.

---

## 3. Tool Registry Specification

| Tool Name | Parameters | Return Type | Description |
|---|---|---|---|
| `search_code` | `query: String, maxResults: int` | `List<SearchResult>` | Performs regex / fuzzy keyword search across indexed source files. |
| `search_docs` | `query: String` | `List<DocSection>` | Searches extracted README and markdown documentation sections. |
| `read_file` | `path: String, startLine: int?, endLine: int?` | `String` | Reads content of a specific file, optionally bounded by line ranges. |
| `read_symbol` | `symbolName: String` | `SymbolDefinition?` | Resolves symbol location and signature from the symbol index. |
| `get_project_summary` | None | `ProjectSummary` | Returns structured project purpose, stack, entry points, and commands. |
| `get_git_status` | None | `GitStatus` | Returns modified, staged, and untracked files. |
| `get_git_diff` | `filePath: String?` | `String` | Returns unified git diff of working directory. |
| `apply_patch` | `filePath: String, replacementContent: String` | `PatchResult` | Generates a staged diff and applies changes upon user confirmation. |
| `run_command` | `command: String` | `CommandOutput` | Executes a shell command in the project directory (requires confirmation for unsafe commands). |
| `run_tests` | `testPath: String?` | `TestResult` | Runs detected test suite (e.g. `npm test`, `pytest`) and reports structured results. |

---

## 4. Human-in-the-Loop Confirmation Policy
- **Auto-approved tools:** `search_code`, `search_docs`, `read_file`, `read_symbol`, `get_project_summary`, `get_git_status`, `get_git_diff`.
- **User-confirmation required tools:**
  - `apply_patch` (User reviews the diff in the Diff Viewer before choosing **Keep & Apply** or **Discard**).
  - `run_command` (If command matches destructive patterns: `rm`, `mkfs`, `git reset --hard`, `git clean -f`, network downloads).
  - Any Git Push or branch deletion.

---

## 5. Multi-Provider Architecture
```dart
abstract class AIProvider {
  String get name;
  String get description;
  bool get isLocal;
  Future<AgentTaskResult> executeTask({
    required String prompt,
    required ProjectContext context,
    required ToolRegistry tools,
    required void Function(AgentStep step) onStep,
  });
}
```
1. `LocalAIProvider`: Connects to on-device LLM engines (llama.cpp / MLC-LLM / local HTTP daemon) for private, zero-latency inference.
2. `ExternalAIProvider`: Connects to OpenAI, Anthropic, or custom remote endpoints with user-supplied API keys.
