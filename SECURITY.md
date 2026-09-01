# SECURITY.md — Nivora Security, Privacy & Sandboxing Policy

## 1. Threat Model & Untrusted Code Execution
Cloned repositories from GitHub must be treated as untrusted code. A repository could contain malicious post-install hooks, obfuscated scripts, or path-traversal payloads.

---

## 2. Core Defenses
1. **Filesystem Sandboxing:**
   - Projects are strictly segregated under `Nivora/projects/<repo_name>/`.
   - Operations attempting path traversal (`../`) out of bounds are blocked.
2. **Command Interception & Approval:**
   - Unsafe commands (`rm -rf`, `mkfs`, arbitrary shell curl-piping) trigger explicit user consent prompts.
3. **Secret Protection:**
   - Files matching `.env*`, `*.pem`, `id_rsa`, `*token*`, `*secret*` are strictly excluded from AI context retrieval prompts.
4. **Local-First Privacy:**
   - Local AI models process code on-device. No telemetry, code snippets, or repository files are transmitted to external servers without user configuration.
