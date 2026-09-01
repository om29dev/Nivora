# RUNTIME.md — Nivora Local Runtime Engine & Environment

## 1. Local Dev Server Daemon (`LocalDevServer`)
Nivora runs a dedicated, in-app HTTP server daemon directly on the physical Android device:
- **Binding Address:** `InternetAddress.loopbackIPv4` (`127.0.0.1` / `localhost`)
- **Default Port:** `5173` (with dynamic fallback to next available port)
- **Serving Architecture:**
  - Serves static assets, compiled HTML/CSS/JS, and single-page application (SPA) bundles directly from the project sandbox root (`/src`, `/public`, `/dist`).
  - Supports client-side routing fallback (SPA index resolution).
  - Handles CORS headers and MIME types for modern ES modules (`application/javascript`, `text/html`, `image/svg+xml`).
- **Browser Compatibility:**
  - Fully accessible from mobile browsers (Google Chrome, Firefox, Brave) via `http://localhost:5173`.
  - Accessible via Nivora's internal In-App Live Preview WebView.
  - Zero cloud relays or external tunneling services required.

---

## 2. Embedded Termux Runtime & Real Process Execution
Android's default `/system/bin/sh` lacks developer toolchains (`npm`, `node`, `git`, `python`, `vite`), returning exit code `127: inaccessible or not found` errors.

To solve this **without requiring the standalone Termux application to be installed**, Nivora embeds its own self-contained Termux runtime:
1. **Self-Contained Bootstrap:** Downloads and extracts official Termux bootstrap archives (`bootstrap-aarch64.zip`, `bootstrap-arm.zip`, `bootstrap-x86_64.zip`) directly into Nivora's private data sandbox (`<app_data>/termux/usr`).
2. **Reconstruction & Permissions:** Recreates symbolic links from `SYMLINKS.txt` and applies `chmod 755` executable permissions to binaries.
3. **Environment & PRoot Mapping:**
   - Prepares full POSIX environment (`$PREFIX`, `$PATH`, `$LD_LIBRARY_PATH`, `$HOME`, `$TMPDIR`).
   - Uses user-space PRoot mapping (`-b <localUsr>:/data/data/com.termux/files/usr`) to eliminate path collisions with Termux packages.
4. **Real Termux Package Management:** Connects to official Termux repositories (`packages.termux.dev`), allowing users to run `pkg install nodejs`, `pkg install python`, `pkg install git`, and `apt update` directly inside Nivora.
5. **Desktop Workstation Mode:** When running on Windows, macOS, or Linux, real system shells (`powershell.exe`, `/bin/sh`) are executed directly.

```text
User Terminal Input / "Run Project"
                │
                ▼
        ProcessManager.start()
                │
    ┌───────────┴───────────┐
    │ Platform Check        │
    ├───────────────────────┤
    │ Android + Termux Ready│ ──► [Runs embedded Termux bash with $PREFIX/bin & $LD_LIBRARY_PATH]
    │ Android (Uninstalled) │ ──► [/system/bin/sh for basic tools or prompts Termux installation]
    │ Desktop (Win/Mac/Lin) │ ──► [Dispatches to host powershell / /bin/sh real system processes]
    └───────────────────────┘
```

---

## 3. Process Execution & Port Detection
- **Interactive Processes:** Long-running processes (`npm run dev`, `python app.py`) are assigned an internal Task ID.
- **Port Listener:** Regex scanner monitors terminal stdout/stderr for port patterns (`localhost:([0-9]+)` or `port ([0-9]+)`).
- **Auto-Preview Trigger:** Detecting a bound port automatically enables the "Open in Chrome" and "Live Preview" actions.
- **Signal Control:** Clean SIGINT / SIGKILL signals allow instant process termination without leaving zombie processes.

---

## 4. Sandboxing & Security Rules
- Each project runs strictly isolated within its active directory (`Nivora/projects/<repo_name>/`).
- Path traversal (`../`) attempting to reach private app directories or external storage without permissions is blocked.
- Environment variables (`.env`, secrets) are protected from external prompt leakage.
