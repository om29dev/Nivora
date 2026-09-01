# TESTING.md — Nivora Testing Strategy & Verification Guidelines

## 1. Test Pyramid
- **Unit Tests (Fast & Isolated):**
  - Project manifest detection (`package.json`, `requirements.txt`).
  - Markdown semantic analyzer section parsing.
  - Symbol extraction regex logic.
  - Context budget ranking and truncation algorithm.
  - Git porcelain status parsing and unified diff generation.
  - Terminal bounded scrollback buffer.
- **Widget Tests (Component & Flow):**
  - Design system component rendering (`NivoraButton`, `NivoraCard`, `NivoraInput`).
  - Home screen repository cloning initiation.
  - File tree expansion.
  - Diff viewer additions/deletions styling.
- **Integration & Manual End-to-End Checklist:**
  - Verify complete workflow from GitHub clone to live preview and commit.

---

## 2. Automated Test Execution
Run all tests locally:
```bash
flutter test
```

Run static analysis:
```bash
flutter analyze
```

---

## 3. End-to-End Hackathon Demonstration Checklist
1. Open Nivora -> verify splash animation & onboarding.
2. Select local AI provider.
3. Paste a public GitHub URL in the Home input bar.
4. Hit "Clone Repository" -> observe verified staged progress steps.
5. Inspect Project Intelligence dashboard (tech stack badges, extracted entry points).
6. Open File Explorer -> navigate into source file -> open in Code Editor.
7. Open AI Assistant -> request a feature or bugfix.
8. Observe agent steps -> review generated diff -> apply patch.
9. Launch project runner -> inspect terminal output -> view Live Preview.
10. Open Camera Debugger -> simulate scanning an error -> see diagnosis.
11. Trigger Voice Coding -> dictate command.
12. Inspect Git Source Control -> commit changes -> view history.
13. Open Office Kit companion -> inspect connection status.
