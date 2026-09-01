# TERMINAL.md — Nivora Terminal & Streaming Console Specifications

## 1. Terminal Architecture
The Nivora terminal bridges Flutter's high-frame-rate UI rendering with real process execution streams:

```text
┌─────────────────────────────────────────────────────────┐
│     Virtualized Terminal ListView (Scrollback Buffer)   │
│          - 2,000 lines max rolling window               │
│          - ANSI color spans (cyan, green, red, yellow)  │
└──────────────────────────┬──────────────────────────────┘
                           │ ▲
              sendInput()  │ │ stdout / stderr stream events
                           ▼ │
┌─────────────────────────────────────────────────────────┐
│                  TerminalService                        │
│          - Buffer management & ANSI parsing             │
│          - Command history (Up/Down navigation)         │
└──────────────────────────┬──────────────────────────────┘
                           │ ▲
                           ▼ │
┌─────────────────────────────────────────────────────────┐
│                   ProcessManager                        │
│          - Workstation Shell Engine (npm, git, vite)    │
│          - Native Android PTY Bridge (/system/bin/sh)   │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Rendering & Virtualization Strategy
- **Bounded Buffer:** Terminal buffer maintains a rolling window capped at 2,000 lines. Older lines are recycled to prevent memory growth or UI stutters on Android devices.
- **Incremental Line Append:** stdout/stderr streams are parsed line-by-line using chunked streams. Only newly arrived lines trigger widget tree updates.
- **ANSI Styling Support:** Supports 16-color ANSI escape sequences (Green, Red, Cyan, Yellow, Bold, Dim) parsed into styled Flutter `TextSpan` elements.

---

## 3. Interactive Capabilities & Ergonomics
- **Command History:** Persistent history allows navigating through previously run commands.
- **Signal Control:** Prominent `Ctrl+C` (SIGINT) button to cancel hanging builds or stop dev servers gracefully.
- **Virtual Developer Bar:** Quick accessory buttons for symbols frequently needed in shell commands: `|`, `&`, `-`, `/`, `~`, `$`, `.`.
- **Live Port Detection:** Scans terminal output for bound addresses (e.g. `http://localhost:5173`) and provides a floating "Open Live Preview" button immediately when detected.
