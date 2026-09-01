# PRODUCT.md — Nivora Complete Product Specification & Screen Flow

## 1. Core User Journey
1. **Launch:** Splash screen with brand animation -> First-time Onboarding -> AI Provider Setup (Default Local).
2. **Home Screen:** Greeting, quick GitHub URL input bar, "Clone Repository" CTA, and list of Recent Local Projects. (Note: No generic "New Project" button; Nivora is repository-first).
3. **Cloning Flow:** Staged backend progress (Connecting -> Downloading -> Detecting stack -> Reading docs -> Mapping symbols -> Ready).
4. **Project Workspace:**
   - **Overview & Intelligence:** Tech stack badges, detected run/build/test commands, architecture summary, AI Readiness indicator.
   - **Files:** Mobile-first file browser with search, icons, and Git modification indicators.
   - **Editor:** Touch-ergonomic code editor with custom developer toolbar (`{ } ( ) ; = > TAB`), line numbers, and AI quick action bar.
   - **AI Agent:** Agentic execution steps, code search summary, proposed line diffs, "Review & Apply Changes" sheet.
   - **Terminal:** Interactive virtualized terminal executing real processes, ANSI styling, port detection.
   - **Runner & Live Preview:** Run dev servers (`npm run dev`, `python app.py`) with an embedded WebView preview surface.
   - **Git Source Control:** Inspect modified/untracked files, line-by-line diff viewer, staging, commit messages, and manual push/pull.
   - **Camera Debugger:** Optical error scanner: point camera at an external monitor error message -> OCR extracts error text -> AI matches local codebase -> proposes fix.
   - **Voice Coding:** Tap microphone button -> voice intent transcribed -> AI agent retrieves code and prepares patch.
   - **Office Kit Companion:** Phone-to-laptop integration for screen mirroring, clipboard synchronization, file transfer, and offloaded heavy builds.

---

## 2. Complete Screen Catalog

### Screen 01: Splash
- Minimalist luxury dark aesthetic.
- Logo: Glowing geometric cyan/teal monogram.
- Subtitle: "Code without the desk."
- Rapid cold-start transition (< 800ms).

### Screen 02-04: Onboarding (3 Steps)
- Step 1: "Your development environment" (Git, Python, Node, Terminal on device).
- Step 2: "AI that understands your repository" (Targeted context retrieval instead of dump).
- Step 3: "Your code stays local" (Offline-first, private).
- Action: "Get Started" saves onboarding completion flag.

### Screen 05: AI Provider Setup
- Choices:
  - Local Model (Default, Private, On-device, Offline-capable).
  - External / Cloud API (Configurable endpoint & API key).
- Can be changed anytime in Global Settings.

### Screen 06: Home Screen
- Header: "Nivora", current greeting ("Good afternoon 👋"), settings gear.
- Prompt: "What are you working on?"
- Input Bar: Paste GitHub URL with clipboard auto-detect.
- Primary Button: [ Clone Repository ].
- Section: "RECENT PROJECTS" with repository cards displaying stack, branch, last activity, and health indicator.

### Screen 07: Clone Modal & Progress
- Validates repository URL and allows branch selection (default: `main`).
- Multi-step verified progress indicators:
  - Connecting to GitHub ✓
  - Downloading repository ✓
  - Detecting project ✓
  - Detecting runtime ✓
  - Reading documentation ✓
  - Building project map ✓
  - Preparing environment ●

### Screen 08: Project Overview & Intelligence
- Overview metrics: Project Name, Tech Stack, Language, Runtime, Package Manager, Branch, Git Status, AI Readiness.
- Primary Action buttons: `[ ✨ Ask AI ]` and `[ ▶ Run ]`.
- Intelligence Cards: Purpose, Architecture, Entry Points, Commands, Dependencies, Key Files.

### Screen 09: File Explorer
- Lazy-loading hierarchical file tree.
- Search filter for quick fuzzy file navigation.
- Status indicators: Added (A), Modified (M), Deleted (D).
- File size, extension icons, fast opening into editor.

### Screen 10: Code Editor
- Line numbers, syntax-aware code presentation in both Light and Dark modes.
- Virtual keyboard toolbar: quick keys `Tab`, `{`, `}`, `(`, `)`, `[`, `]`, `;`, `=>`, `"`, `'`, `/`, `$`.
- Status header: File path, unsaved change dot, Save button.
- AI Code Scanner: Tapping the scanner action (`Icons.document_scanner_rounded`) automatically feeds the current file buffer into the active continued AI chat session.

### Screen 11: AI Agent Assistant
- Repository-level scan on initial open: reads documentation (`README.md`), detected stack, symbols, and provides 3 actionable recommendations.
- Multi-session chat history: switch between previous chats and start fresh chats with one tap.
- Prompt editing: edit icon on all user messages allows tweaking and re-submitting queries.
- In-editor file feeder: seamlessly feeds active code files into the ongoing conversation.
- Execution progression feed:
  - `Searching project documentation... ✓`
  - `Searching source code... ✓`
  - `Relevant files: src/App.tsx`
  - `Generating patch... ✓`
- Action: [ Review Changes ] -> opens Diff Viewer sheet.

### Screen 12: Diff Viewer
- Unified line diff with colored background highlights (green for additions, red for deletions).
- Height-bounded modal sheet to eliminate layout overflows.
- Actions: [ Discard ] or [ Keep & Apply ].

### Screen 13: Terminal
- Interactive console with ANSI escape sequence parser and Workstation Shell Engine routing.
- Virtualized scrollback buffer (bounded at 2,000 lines to prevent frame drops).
- Actions: Send input, Send Ctrl+C, Clear, Copy buffer.
- Running process bar showing PID, elapsed time, and open ports.

### Screen 14: Project Runner & Live Preview
- Native in-app loopback HTTP dev server daemon (`LocalDevServer` on `http://localhost:5173`).
- Split or tabbed view: Dev server terminal output on bottom, Live WebView preview on top.
- Preview toolbar: Address bar (`http://localhost:5173`), reload button, and direct launch into mobile Google Chrome.

### Screen 15: Git Source Control
- Staged / Unstaged change lists.
- Diff inspection per file.
- Commit message input field.
- [ Commit ] action with author & timestamp.
- Branch switcher and manual [ Pull ] / [ Push ] buttons.

### Screen 16: Camera Debugger
- Camera viewfinder with target scanning box.
- [ Scan Error ] button triggering OCR.
- Extracted error preview & repository lookup.
- AI diagnosis card with [ Apply Suggested Fix ].

### Screen 17: Voice Coding Modal
- Pulsing audio waveform recording.
- Real-time transcription display.
- [ Send to AI Agent ] trigger.

### Screen 18: Office Kit Companion
- Connection status: Phone <---> Laptop.
- Features: Screen Mirroring, Shared Clipboard, Bidirectional File Transfer, Compute Offload.

### Screen 19: Settings (Global & Project)
- Global: AI Provider, Model Selection, Runtime Diagnostics, Permissions, Theme (Dark/Light/System).
- Project: Run/Build/Test command overrides, Environment variables, Index refresh.
