# Tutorialinator Templates

## Current Architecture: Single HTML File

The tutorialinator generates **self-contained HTML files** — no build step, no dependencies, no framework. Each tutorial is a single `.html` file that opens directly in any browser.

## Reference Implementation

The V3 reference implementation lives at:
`/Users/masud/hex-code-tutorial/src/demo-v3.html`

This file demonstrates every feature of the design system:
- Floating glass sidebar navigation
- Cinematic full-viewport heroes with character reveal
- 3D card tilt on hover
- Bento grid layouts
- Interactive widgets (Hex Digit Builder, Color Wheel, Channel Mixer)
- Code sandboxes with line numbers and live preview
- Quizzes with staggered animations
- XP gamification with particle bursts
- Canvas-based video player
- Cursor glow, scroll progress, toast notifications

## What the LLM Generates

The LLM generates the **entire HTML file** from scratch for each tutorial, using:

1. **SKILL.md** — The complete design system specification (CSS variables, typography, glass morphism, animations, section templates, widget patterns, JS systems)
2. **Widget Pattern Library** — Inspiration for topic-specific interactive elements
3. **Creative freedom** — The LLM adapts the design system to each topic, choosing appropriate widgets and accent colors

## Legacy Templates

The `vite-react/` directory contains legacy Vite + React + TypeScript templates from the previous version. These are **no longer used** — the skill now generates single HTML files instead. The directory is preserved for reference only.
