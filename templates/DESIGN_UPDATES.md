# Design System: V3 Update

## What Changed

The tutorialinator has been completely redesigned with the V3 design system — a cinematic, dark glass morphism aesthetic that feels like a premium interactive learning app.

### Architecture Change
- **Before**: Vite + React + TypeScript + Tailwind multi-file project
- **After**: Single self-contained HTML file (one `<style>`, one `<script>`, zero dependencies)

### Design Language Change
- **Before**: "Pure black and white. No grays, no colors. Bold and clean."
- **After**: Solid black background (#000) with glass morphism overlays, topic-specific accent colors, multi-layer depth shadows, and rich micro-interactions.

### Key Design Elements

1. **Glass Morphism** — `rgba(255,255,255,0.04)` backgrounds with `blur(24px)` backdrop-filter
2. **Floating Sidebar** — Vertical glass pill anchored to left edge with chapter dots, section progress, XP badge
3. **Cinematic Heroes** — Full viewport height, massive type (`clamp(64px, 12vw, 140px)`), character-by-character reveal
4. **3D Card Tilt** — `perspective(800px) rotateY/X` on mousemove
5. **Bento Grids** — Spatial layouts for related content
6. **Topic-Specific Widgets** — Purpose-built interactive elements per tutorial
7. **XP Gamification** — Particle burst animations, toast notifications
8. **Noise Texture** — CSS-only `feTurbulence` overlay at 2.8% opacity
9. **Cursor Glow** — 300px radial gradient following mouse with eased interpolation
10. **Staggered Animations** — Section children reveal in sequence (tag → h2 → body → card)

See SKILL.md for the complete specification.
