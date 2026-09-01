# UI_GUIDELINES.md — Nivora Design System & UX Standards

## 1. Dual-Theme Visual Aesthetics

Nivora features a coherent dual-theme system designed specifically for high legibility on mobile screens:

### A. Dark Palette (Default)
- `background`: `#090D16` (Deep space black)
- `surface`: `#111827` (Matte dark slate)
- `surfaceElevated`: `#1F2937` (Elevated card slate)
- `surfaceHighlight`: `#374151` (Border & divider grey)
- `textPrimary`: `#F8FAFC` (Crisp off-white)
- `textSecondary`: `#94A3B8` (Muted grey)
- `border`: `#1E293B` (Subtle 1px border)

### B. Light Palette
- `background`: `#F8FAFC` (Crisp modern off-white)
- `surface`: `#FFFFFF` (Pure white card surface)
- `surfaceElevated`: `#F1F5F9` (Soft elevated slate card)
- `surfaceHighlight`: `#E2E8F0` (Divider & subtle border)
- `textPrimary`: `#0F172A` (Deep navy / dark slate)
- `textSecondary`: `#64748B` (Medium slate grey)
- `border`: `#CBD5E1` (Clean 1px border)

### C. Accent & Semantic Tokens (Both Themes)
- `primary`: `#06B6D4` (Electric Cyan)
- `primaryVariant`: `#0EA5E9` (Sky Blue)
- `secondary`: `#8B5CF6` (Subtle Violet)
- `success`: `#10B981` (Emerald Green)
- `warning`: `#F59E0B` (Amber Orange)
- `error`: `#EF4444` (Coral Red)

### D. Theme-Adaptive Getters
To prevent hardcoded color bugs, components use context-aware theme getters:
- `AppColors.text(context)` -> Returns `#F8FAFC` in dark mode, `#0F172A` in light mode.
- `AppColors.textSecondaryOf(context)` -> Returns `#94A3B8` in dark, `#64748B` in light.
- `AppColors.surface(context)` -> Returns active card surface.
- `AppColors.surfaceElevated(context)` -> Returns elevated card / chip surface.
- `AppColors.border(context)` -> Returns active 1px border color.

---

## 2. Nivora Component Suite

All UI interfaces adhere to standardized semantic components:
- `NivoraButton`: Primary action button with subtle glow, loading state, and tactile feedback.
- `NivoraSecondaryButton`: Outlined, theme-adaptive secondary button.
- `NivoraInput`: Clean input with adaptive fill, border, clear action, and validation.
- `NivoraCard`: Rounded container with 1px adaptive border and elevation.
- `NivoraChip`: Status or language tag with semantic colors.
- `NivoraAppBar`: Minimalist top bar with title, back navigation, and contextual actions.
- `NivoraBottomSheet`: Height-bounded (`maxHeight: 85%`) bottom sheet with drag handle to prevent screen overflow.
- `NivoraDialog`: Confirmation modal for destructive actions.
- `NivoraStatus`: Colored dot indicating process, git, or runtime state.
- `NivoraProgress`: Staged step progression indicator with verified checkmarks.
- `NivoraProjectCard`: Rich project card displaying language, branch, and health.
- `NivoraFileRow`: File tree row with file-type icons, modification badge, and touch padding.
- `NivoraCodeHeader`: Breadcrumb bar showing active file and dirty indicator.
- `NivoraTerminalLine`: Virtualized mono line supporting ANSI styling.
- `NivoraAIMessage`: Agent card with execution badges, action widgets, and user message edit capability.
- `NivoraAgentStep`: Animated bullet showing real-time agent activity.
- `NivoraDiffViewer`: Scroll-protected unified diff viewer with addition (green) and deletion (red) lines.
- `NivoraEmptyState`: High-context empty state with clear call to action.
- `NivoraErrorState`: Diagnostic card explaining error, cause, and "Fix with AI" CTA.
- `NivoraBottomNavBar`: Floating pill-shaped navigation bar (26dp radius, 1px border) with 4 symmetrical destinations.
- `NivoraFloatingAIButton`: 66dp circular AI Agent floating button rising 22dp above the navigation bar with glowing concentric halo ring.

---

## 3. Touch Ergonomics & Mobile-First UX
- **Minimum Touch Target:** `48x48dp` for all buttons and interactive rows.
- **Virtual Developer Accessory Bar:** Pinned above the software keyboard:
  `[Tab]  [ { ]  [ } ]  [ ( ]  [ ) ]  [ ; ]  [ => ]  [ " ]  [ $ ]  [ / ]`
- **Bottom Sheet Bounds:** All bottom sheets are bounded to 85% viewport height with internal scrolling, eliminating bottom overflow warnings.
- **Chat Ergonomics:**
  - Multi-session drawer for accessing past conversations.
  - One-tap prompt editing on all user message bubbles.
  - Dedicated "Keep & Apply" and "Discard" actions on diff proposals.
