## Non-Video Input Modes

This section extends the tutorialinator skill to support tutorial generation without video input.

### Mode Detection

The skill auto-detects the input mode from user requests:

1. Check for video file path first (original mode)
2. Check for URLs in input (Research Mode)
3. Check for "research" or "deep dive" keywords (Deep Research Mode)
4. Default to Topic Mode for teaching requests

---

## Mode 1: Topic Mode

**Trigger:** "Create a tutorial to teach me [topic]"

### Workflow

1. **Topic Analysis** — Determine prerequisites, core concepts, 3-5 chapters, code-heaviness
2. **Content Planning** — Design learning path, identify 2-4 interactive widgets per chapter, plan progressive difficulty
3. **Widget Design** — Choose topic-specific widgets from the pattern library (or invent new ones)
4. **Content Generation** — Write conversational explanations, working code examples, quiz questions
5. **Site Generation** — Build the single self-contained HTML file

### Quality Validation
- [ ] Each chapter has >= 1 working code sandbox
- [ ] Each chapter has >= 1 interactive widget (topic-specific, not generic)
- [ ] Code examples build on each other progressively
- [ ] No unexplained jargon
- [ ] Quiz questions test understanding, not memorization
- [ ] Content flows logically (can read start to finish)

---

## Mode 2: Research Mode

**Trigger:** "Build a tutorial based on these resources: [URLs]"

### Workflow

1. **URL Fetching** — Fetch and analyze each provided URL for content, code snippets, key takeaways
2. **Content Synthesis** — Identify common themes, contradictions, gaps, best examples per source
3. **Tutorial Structuring** — Create unified learning path with source attribution per chapter
4. **Widget Design** — Choose widgets appropriate to the synthesized content
5. **Site Generation** — Build the single HTML file with inline citations

### Attribution Requirements (Non-Negotiable)
- Every code example must cite its source URL
- Direct quotes in blockquotes with attribution
- Source badge or citation near attributed content
- "Further Reading" section at tutorial end

### Quality Validation
- [ ] Every chapter cites at least one source
- [ ] No plagiarism (rewritten, not copied)
- [ ] Code examples attributed to origin
- [ ] Contradictions are acknowledged, not hidden
- [ ] Links to original sources are included

---

## Mode 3: Deep Research Mode

**Trigger:** "Research [topic] thoroughly and teach me"

### Workflow

1. **Research Planning** — Identify core concepts, related topics, web search queries
2. **Web Research** — Execute searches, gather 5-15 quality sources, filter by quality/recency
3. **Deep Analysis** — Build concept relationships, identify misconceptions, find expert consensus
4. **Tutorial Generation** — Create comprehensive content including misconceptions section, deep dives, resource list
5. **Widget Design** — Choose widgets that serve both teaching and exploration
6. **Site Generation** — Build the single HTML file with all content and citations

### Quality Validation
- [ ] Research covers >= 5 quality sources
- [ ] Official documentation is cited
- [ ] Misconceptions section has >= 3 items
- [ ] No factual errors (verified against official docs)
- [ ] Balanced view of disputed topics
- [ ] All external links are included
- [ ] Resource list at end

---

## Output Format (All Modes)

All modes output a **single self-contained HTML file** at `~/[topic]-tutorial/src/tutorial.html`.

The file follows the V3 design system: dark glass morphism, floating sidebar nav, cinematic heroes, 3D cards, bento grids, XP gamification, cursor glow, and topic-specific interactive widgets.

See SKILL.md for the complete design system specification and quality standards.

---

## Usage Examples

```bash
# Topic Mode
/tutorialinator "Create a tutorial to teach me React hooks"
/tutorialinator "Build a tutorial on TypeScript generics for beginners"

# Research Mode
/tutorialinator "Build a tutorial based on these resources:" \
  "https://react.dev/learn/synchronizing-with-effects" \
  "https://overreacted.io/a-complete-guide-to-useeffect/"

# Deep Research Mode
/tutorialinator "Research Rust ownership thoroughly and teach me"
/tutorialinator "Deep dive into WebAssembly and create a tutorial"
```
