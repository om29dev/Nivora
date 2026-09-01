# GIT_WORKFLOW.md — Nivora Git & Source Control Engine

## 1. Supported Git Capabilities
Nivora provides a real local Git workflow:
- `git clone <url> <dest>`: Clones remote public repositories with real progress updates.
- `git status --porcelain`: Surfaces modified (M), added (A), deleted (D), and untracked (??) files.
- `git diff`: Computes line-by-line additions and deletions for visual inspection.
- `git add <files>`: Stages specific files or all changes.
- `git commit -m "<message>"`: Records commits with author attribution.
- `git branch`: Lists, creates, and switches branches.
- `git fetch` & `git pull`: Syncs downstream commits from the upstream origin.
- `git push`: Pushes commits upstream with explicit user confirmation.

---

## 2. Safety & Guardrail Guarantees
- **No Automatic Push:** The AI agent and the application will NEVER automatically push to a remote repository.
- **Explicit Discard Confirmation:** Discarding changes (`git checkout -- <file>`) triggers a modal warning.
- **Diff Inspection:** All AI-generated patches must pass through the Git diff viewer before user acceptance.
