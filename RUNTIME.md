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

## 2. Workstation Shell Engine & Command Routing
Android's default `/system/bin/sh` lacks developer toolchains (`npm`, `node`, `git`, `python`, `vite`), normally causing exit code `127: inaccessible or not found` errors.

To solve this, Nivora features a dual-layer command router:
1. **Developer Toolchain Routing:** Commands matching `npm`, `npx`, `node`, `vite`, `git`, `python`, `python3`, `pip`, `ls`, `pwd`, `cat` are intercepted by Nivora's Workstation Shell Engine and executed with genuine runtime emulations and live file system operations.
2. **Native Android Fallback:** Pure shell utilities are dispatched to `/system/bin/sh` or terminal PTY bridges when native binaries exist.

```text
User Terminal Input / "Run Project"
                │
                ▼
        ProcessManager.start()
                │
    ┌───────────┴───────────┐
    │ Developer Command?    │
    ├───────────────────────┤
    │ YES: Workstation Shell│ ──► [Starts LocalDevServer:5173 / Streams logs]
    │ NO:  /system/bin/sh   │ ──► [Dispatches to Android native process]
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
- Path traversal (`../`) attempting to reach private app directories (`/data/data/com.nivora.app/databases`) or external storage without permissions is blocked.
- Environment variables (`.env`, secrets) are protected from external prompt leakage.
