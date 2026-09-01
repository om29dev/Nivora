# REPOSITORY_INTELLIGENCE.md — Repository Intelligence & Context Retrieval

## 1. Overview
The Repository Intelligence Engine is Nivora's core brain. Rather than treating codebases as dumb text files, it constructs a multi-layered structured index of the repository upon cloning:

```text
Filesystem Scan ──> Manifest Detection ──> Markdown Analysis ──> Symbol Indexing
                                                                       │
User Prompt ──> Targeted Context Ranking ──> Context Budget (<4k) ──> AI Agent
```

---

## 2. Subsystems

### 2.1 RepositoryScanner
- Scans directory trees recursively while strictly ignoring:
  - `node_modules/`, `vendor/`, `target/`, `build/`, `dist/`, `.next/`, `__pycache__/`
  - `.git/objects/`, `.gradle/`, `.idea/`, `.vscode/`
  - Binary files (images, audio, video, zip, compiled archives)
- Collects file relative paths, file sizes, and extensions.

### 2.2 ProjectDetector
Inspects root manifests to determine tech stack, runtime, and default scripts:
- `package.json` -> Node.js / TypeScript / React / Next.js / Vite / Express
- `requirements.txt`, `pyproject.toml`, `Pipfile` -> Python / Django / FastAPI / Flask
- `Cargo.toml` -> Rust
- `go.mod` -> Go
- `pubspec.yaml` -> Flutter / Dart
- `Makefile` -> C/C++ / Make automation

### 2.3 MarkdownAnalyzer (Markdown-First Semantic Understanding)
Documentation is the highest-signal context for AI.
Parses `README.md`, `CONTRIBUTING.md`, and `docs/` using section parsing heuristics:
- **Project Purpose & Pitch:** Overview paragraphs.
- **Tech Stack & Architecture:** Listed technologies and folder structure notes.
- **Dev Commands:** Regex extraction of `npm run dev`, `python app.py`, `pytest`, etc.
- **Environment & Setup:** `.env` notes and prerequisite instructions.
Generates a compact `ProjectSummary` object (< 400 tokens).

### 2.4 SymbolIndexer
Lightweight regex and AST parsing across code files:
- **Functions:** `function foo(...)`, `const foo = (...) =>`, `def foo(...):`
- **Classes:** `class Foo`, `interface Foo`, `type Foo`
- **Exports:** `export default`, `module.exports`
- **Routes:** `app.get('/path')`, `router.post(...)`, `@app.route(...)`
Stored in a fast in-memory map keyed by symbol name and relative file path.

### 2.5 TargetedContextRetriever & Budget Manager
When a user asks: *"Add dark mode to the dashboard"*
1. Match query against symbol index (`Dashboard`, `theme`, `DarkMode`).
2. Match query against file paths (`dashboard.tsx`, `theme.ts`, `style.css`).
3. Match query against documentation sections.
4. Rank matches by relevance score.
5. Fill context budget:
   - Priority 1: Project Summary (fixed ~350 tokens)
   - Priority 2: Direct file matches (~2,000 tokens)
   - Priority 3: Extracted symbol signatures (~500 tokens)
   - Priority 4: Git modified files (~500 tokens)
6. Total budget capped at 4,000 tokens to ensure ultra-fast local inference.
