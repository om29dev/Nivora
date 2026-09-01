# OFFICE_KIT.md — Nivora Office Kit Companion Integration

## 1. Product Philosophy & Concept
The smartphone is the developer's primary, autonomous workstation. The laptop is an optional, wireless **accelerator** used when sitting at a desk for wide-screen mirroring, shared keyboard/mouse control, and compute offload.

```text
┌───────────────────────────┐                 ┌───────────────────────────┐
│     SMARTPHONE (Android)  │                 │     LAPTOP / WORKSTATION  │
│   (Primary Orchestration) │ ◄─────────────► │   (Hardware Accelerator)  │
│   - Git & Code Sandboxing │   Office Kit    │   - Wide-screen Mirroring │
│   - Live HTTP Dev Server  │   Companion     │   - Shared Keyboard/Mouse │
│   - AI Retrieval & Agent  │   Protocols     │   - Heavy Compiler & LLM  │
└───────────────────────────┘                 └───────────────────────────┘
```

---

## 2. Core Protocols & Capabilities

### A. Local Network Discovery & P2P Pairing
- **Discovery:** Automatic discovery via mDNS / UDP broadcast (`_nivora-officekit._tcp`) over local Wi-Fi or Wi-Fi Direct.
- **Pairing:** Secure 6-digit one-time PIN or QR code authentication establishing an encrypted TLS / Noise protocol channel.
- **Zero Cloud Dependence:** All traffic remains strictly within the local area network (LAN). No cloud relay or third-party servers required.

### B. High-Fidelity Screen Mirroring
- Streams the phone's live workspace (terminal, editor, preview) to the desktop browser or desktop app at 60fps.
- Low latency (<25ms) via WebRTC / H.264 video pipeline.
- Full touch and mouse pass-through: clicking on the desktop monitor dispatches touch events directly to the phone.

### C. Bi-Directional Clipboard Bridge
- Copies code, error traces, or URLs on the Android device, and they are immediately available on the desktop clipboard.
- Desktop clipboard changes can be pasted seamlessly into the phone's code editor or terminal input.

### D. File Synchronization & Patch Streaming
- Transmits repository archives, diff patches, and build assets over high-speed local TCP/WebSocket sockets.
- Allows editing files on the desktop and having changes sync bidirectionally to the phone sandbox with conflict resolution.

### E. Compute & Heavy LLM Offload Mode
- When connected, heavy tasks can be offloaded to the laptop accelerator:
  - Docker container builds and multi-gigabyte dependency compilations.
  - Larger quantized LLM inference (e.g. 14B / 32B models) running on the laptop's GPU.
- The phone maintains full orchestration and retains state authority.

---

## 3. Fallback & Transparency Guarantees
- **100% Standalone Capability:** If the companion laptop is disconnected or unavailable, Nivora executes 100% locally on the phone with zero loss of core features.
- **Live Status Indicator:** Real-time connection badge (`Ready`, `Connected`, `Offline`) displayed in the top navigation bar.
- **Graceful Reconnection:** Network drops automatically re-sync clipboard and state upon reconnection without crashing running servers or losing unsaved editor buffers.
