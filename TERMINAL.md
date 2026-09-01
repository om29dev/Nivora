# TERMINAL.md — Nivora Terminal & Streaming Console Specifications

## 1. Terminal Architecture & Embedded Termux Runtime
The Nivora terminal bridges Flutter's high-frame-rate UI rendering with real process execution streams and an embedded, self-contained **Termux Linux Runtime Environment**:

```text
┌─────────────────────────────────────────────────────────┐
│     Virtualized Terminal ListView (Scrollback Buffer)   │
│          - 2,000 lines max rolling window               │
│          - ANSI color spans (cyan, green, red, yellow)  │
│          - Real-time Termux status & installer banner   │
└──────────────────────────┬──────────────────────────────┘
                           │ ▲
              sendInput()  │ │ stdout / stderr stream events
                           ▼ │
┌─────────────────────────────────────────────────────────┐
│                   ProcessManager                        │
│          - Real OS process execution (no mocked output) │
│          - Port extraction & Live Preview watcher       │
│          - Android: Embedded Termux bash / proot / sh   │
│          - Desktop: Host powershell / /bin/sh           │
└──────────────────────────┬──────────────────────────────┘
                           │ ▲
                           ▼ │
┌─────────────────────────────────────────────────────────┐
│              TermuxEnvironmentService                   │
│          - Zero external Termux app dependency          │
│          - Self-contained bootstrap (aarch64/arm/x86_64)│
│          - SYMLINKS.txt parsing & chmod 755             │
│          - Termux package management (pkg, apt)         │
│          - User-space PRoot /data/data/com.termux map   │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Zero-Dependency Termux Package Execution
Nivora does **NOT** require the standalone Termux application to be installed on the device. Instead, it embeds and manages an isolated Termux prefix:
- **Root Directory:** `<app_data>/termux/`
- **Prefix Path (`$PREFIX`):** `<app_data>/termux/usr/`
- **Home Path (`$HOME`):** `<app_data>/termux/home/`
- **Official Termux Packages:** Uses official Termux repositories (`packages.termux.dev`), allowing developers to run:
  - `pkg install nodejs`
  - `pkg install python`
  - `pkg install git`
  - `pkg install rust` / `pkg install clang`
- **Path Mapping:** Uses user-space PRoot remapping (`-b <localUsr>:/data/data/com.termux/files/usr`) so that official Termux `.deb` packages execute without path conflict.
- **Desktop Fallback:** When running on desktop workstations (Windows, macOS, Linux), real system processes (`powershell.exe`, `/bin/sh`) are executed directly.

---

## 3. Rendering & Virtualization Strategy
- **Bounded Buffer:** Terminal buffer maintains a rolling window capped at 2,000 lines. Older lines are recycled to prevent memory growth or UI stutters on Android devices.
- **Incremental Line Append:** stdout/stderr streams are parsed line-by-line using chunked UTF-8 streams. Only newly arrived lines trigger widget tree updates.
- **ANSI Styling Support:** Supports 16-color ANSI escape sequences (Green, Red, Cyan, Yellow, Bold, Dim) parsed into styled Flutter `TextSpan` elements.

---

## 4. Interactive Capabilities & Ergonomics
- **Command History:** Persistent history allows navigating through previously run commands.
- **Signal Control:** Prominent `Ctrl+C` (SIGINT / SIGKILL) button to cancel hanging builds or stop dev servers gracefully.
- **Virtual Developer Bar:** Quick accessory buttons for symbols and Termux commands: `pkg update`, `pkg install nodejs`, `pkg install python`, `pkg install git`, `npm run dev`, `git status`, `git diff`, `ls -la`, `Ctrl+C`.
- **Live Port Detection:** Scans terminal output for bound addresses (e.g. `http://localhost:5173` or `127.0.0.1:8000`) and provides a floating "Open Live Preview" button immediately when detected.
