# PROJECT.md — Nivora Project Definition & Strategy

## 1. Vision
**Code without the desk.**  
Nivora turns modern Android smartphones into AI-native, high-performance developer workstations capable of running, editing, testing, and shipping real GitHub repositories without needing a laptop or desktop computer.

## 2. Target Users
- **Mobile-first Developers:** Engineers on commutes, traveling, attending hackathons, or away from their workstations.
- **AI-native Builders & "Vibe Coders":** Developers who leverage agentic AI to inspect, refactor, and generate features on the fly.
- **On-call & DevOps Engineers:** Fast incident response, hotfixing, diagnosing build errors, running test suites from anywhere.
- **Hackathon Competitors:** Fast prototyping and live demos directly from a handheld device.

## 3. Core Problem Statement
Existing mobile development tools fall into two unacceptable categories:
1. **Remote IDEs / Web View wrappers:** Require persistent high-bandwidth internet, introduce high input latency, disconnect on weak signals, and transmit all code to remote servers.
2. **Termux / Bare Shells:** Powerful but lack ergonomic mobile UI, require arduous terminal typing on small virtual keyboards, have zero repository awareness, and lack integrated agentic AI workflows.

## 4. Product Promise
- **Zero-Setup Cloning:** Paste any GitHub URL, and Nivora clones, inspects the tech stack, reads README/docs, and configures the environment automatically.
- **Local & Private:** Code and AI operations run locally with full privacy and zero telemetry leakage.
- **Targeted Repository Intelligence:** Nivora indexes symbols and architecture so AI gets surgical context instead of token bloat.
- **Real Local Runtimes:** Real Node.js, Python, Git, and Shell commands running directly on the device.
- **Phone-Native Ergonomics:** Touch-friendly keyboard accessories, camera error scanning (OCR-to-fix), and voice-driven agent commands.
- **Office Kit Companion:** Phone acts as the primary workstation; laptops act as seamless accelerators for large builds and mirroring.

## 5. Non-Goals
- We are NOT building a generic chatbot like ChatGPT in an iframe.
- We are NOT copying a desktop IDE layout with 40 microscopic menus onto a 6-inch screen.
- We are NOT supporting obsolete non-standard platforms; Android is the first-class target.
- We are NOT implementing auto-push or autonomous unattended code pushing.

## 6. Hackathon Alignment (iQOO Hackathon 2026)
- **Challenge:** Developer Tools Challenge.
- **Key Differentiators:** True local runtime, repository intelligence, agentic diff-and-apply, camera debugging, voice coding, and Office Kit companion integration.
