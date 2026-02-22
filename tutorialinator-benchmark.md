# Tutorialinator Skill — Mini Benchmark

**Version**: 1.0
**Date**: 2026-02-19
**Evaluation method**: Automated structural checks + human rubric scoring
**Tutorials evaluated**: 7 real outputs from `/Users/masud/*-tutorial/src/tutorial.html` (6 scored; 1 excluded as intentional stub)

---

## 1. What the System Does

The `/tutorialinator` skill transforms a user prompt (video file path, topic phrase, or URLs) into a **single self-contained HTML tutorial file**. The file must deliver interactive learning — code sandboxes, gamified quizzes, XP rewards, chapter navigation — with no build step and no dependencies.

The system has four modes: **Video** (from a local `.mp4`), **Topic** (from Claude's knowledge), **Research** (from provided URLs), and **Deep Research** (web search). All outputs must follow a strict design system and pedagogical structure regardless of mode.

---

## 2. Success Criteria (Defined Before Scoring)

A passing output must score **≥ 3.0/5.0 on every dimension** and **≥ 3.5/5.0 overall**.

**Hard-fail gates** — any one failure disqualifies the output regardless of other scores:
- File is under 20KB (indicates a stub, not a real tutorial)
- Zero interactive quiz elements
- Zero chapter structure (`div.chapter`)
- All required keyframes (8) missing

---

## 3. Rubric

### Dimension A: Technical Correctness (weight 25%)

| Score | Anchor |
|-------|--------|
| 5 | Braces balanced; all 8 required keyframes present; chapter structure valid; all interactive IDs resolve |
| 4 | 7/8 keyframes; one minor element missing but fully functional |
| 3 | 6–7/8 keyframes or 1 structural issue; core interactivity intact |
| 2 | ≤ 5 keyframes OR missing chapter structure, breaking navigation |
| 1 | Missing most keyframes; no chapters; output is a static stub |

**Automated checks (run on every output):**
- Brace balance: `{` count == `}` count
- Chapter structure: `div.chapter` count > 0
- Required keyframes present: `fadeUp`, `shake`, `confettiBurst`, `timerArc`, `particleBurst`, `charReveal`, `fadeIn`, `scaleIn`

### Dimension B: Design System Fidelity (weight 25%)

| Score | Anchor |
|-------|--------|
| 5 | All 7 required UI elements present: CSS vars (`--bg`), noise overlay, Google Fonts, sidebar, cursor glow, scroll progress, toast |
| 4 | 6/7 elements present |
| 3 | 5/7 elements present |
| 2 | 3–4/7 elements present |
| 1 | ≤ 2/7 elements present |

**Automated checks:**
- `--bg` CSS variable
- `body::after` noise overlay
- `fonts.googleapis.com` link
- `.sidebar` element
- `cursorGlow` element
- `scroll-progress` element
- `g-toast` element

### Dimension C: Interactive Learning Elements (weight 25%)

A **challenge element** is anything that requires the learner to actively do or decide something — a code sandbox, a config/prompt editor, a drag-and-drop widget, a decision scenario tool, a Parsons problem, etc. The right challenge element depends on the topic: code sandboxes for code-heavy topics; purpose-built interactive widgets for conceptual or process topics. The absence of a code sandbox is not itself a failure if an equivalent challenge element is present.

| Score | Anchor |
|-------|--------|
| 5 | Every chapter has ≥ 1 challenge element (sandbox or equivalent interactive widget) AND ≥ 1 quiz AND XP system AND 3D tilt |
| 4 | Most chapters meet the above; 1 chapter missing a challenge element or quiz |
| 3 | All chapters have quizzes but some lack any challenge element, OR all chapters have challenge elements but some lack quizzes |
| 2 | Chapters have either quizzes OR challenge elements but not consistently both; XP present |
| 1 | No challenge elements, no quizzes; purely static text and code blocks |

**Automated checks:**
- Sandbox count (`sbCode\d` pattern) — counts code sandboxes specifically
- Quiz reference count (`"quiz\d"` pattern)
- XP system present (`addXP` or `gXp`)
- 3D tilt present (`perspective` + `rotateX`)

**Note**: Low sandbox count alone does not lower the C score if interactive widgets fill that role. Human judgment is required to assess whether non-sandbox challenge elements are present and purposeful.

### Dimension D: Pedagogical Quality — Quiz Bloom's Level (weight 25%)

| Score | Anchor |
|-------|--------|
| 5 | All quiz questions require Application (L3) or higher — learner must apply, analyze, or evaluate, not scan for the answer |
| 4 | Majority of questions at L3+; at most 1 recall-level question |
| 3 | Mixed: roughly half at L3+, half at recall level |
| 2 | Most questions are recall-level (answer findable in adjacent text or specific video detail) |
| 1 | All recall; no application, analysis, or evaluation questions |

**Human-scored.** For each quiz question, assess: could a learner answer this by scanning the 3 paragraphs before it? If yes → recall (L1/L2). If it requires applying a rule to a new scenario → application (L3+).

---

## 4. Test Cases

Three tutorials were selected to span the quality range:

### Test Case 1 — Strong Output: `css-grid-tutorial`

**Mode**: Topic Mode
**File**: `css-grid-tutorial/src/tutorial.html` (69KB, 4 chapters)

Chosen as the "typical good case" — a concrete technical topic with natural widget opportunities and well-defined progressive structure.

### Test Case 2 — Partial Failure: `goose-extensions-tutorial`

**Mode**: Video Mode
**File**: `goose-extensions-tutorial/src/tutorial.html` (41KB, 3 chapters)

Chosen as the edge case — a shorter video-mode output where multiple spec requirements were dropped, representing what happens at the boundary of "acceptable" quality.

### Test Case 3 — Strong Output with a Specific Gap: `prototyping-process-tutorial`

**Mode**: Video Mode (or Research Mode)
**File**: `prototyping-process-tutorial/src/tutorial.html` (88KB, 5 chapters)

Chosen as a counterpoint to TC1 — technically strong and with the best quiz quality in the entire batch, but with a consistent gap (zero code sandboxes) that reveals a pattern across the skill's outputs.

> **Note on `python-benefits-tutorial`**: This 10KB file (0 chapters, 0 keyframes, 0 interactive elements) was an intentionally generated minimal stub — not a failed full run. It is excluded from formal test case scoring but included in the automated check table and referenced in Section 8 to illustrate what the hard-fail gate is designed to catch.

---

## 5. Automated Check Results (All 7 Outputs)

| Tutorial | Chapters | Keyframes (of 8) | Sidebar | Sandboxes | Quizzes | Size KB | Brace bal. |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| css-grid | 4 | **8** ✅ | ✅ | 3 | 3 | 69 | 0 ✅ |
| goose-ai | 4 | **7** ⚠️ | ✅ | 2 | 3 | 86 | 0 ✅ |
| vibe-coding | 5 | **7** ⚠️ | ✅ | 0 ❌ | 0 ❌ | 1895\* | 0 ✅ |
| python-benefits† | **0** ❌ | **0** ❌ | ❌ | 0 ❌ | 0 ❌ | 10 | 0 ✅ |
| goose-extensions | 3 | **7** ⚠️ | ❌ | 0 ❌ | 2 | 41 | 0 ✅ |
| goose-workflow | 5 | **8** ✅ | ✅ | 3 | 4 | 67 | 0 ✅ |
| prototyping | 5 | **8** ✅ | ✅ | 0 ❌ | 5 | 88 | 0 ✅ |

\* *vibe-coding is 1.9MB because it contains an embedded base64-encoded video (`data:video/mp4;base64,...`) — a Video Mode output where the agent inlined the source video directly into the HTML.*

† *python-benefits was an intentionally generated minimal stub, excluded from test case scoring.*

**Cross-output patterns (6 real outputs, excluding stub):**
- `confettiBurst` keyframe missing in **3/6 real outputs** (50%) — the single most common missing element
- Code sandboxes missing in **3/6 real outputs** (50%) — the most widespread spec violation; notably present in both video-mode and topic-mode outputs
- Brace balance is **0 in every output** — no structural JS/CSS corruption in any tutorial
- Quizzes present in **5/6 real outputs** (83%) — the most reliably implemented required element

---

## 6. Scored Results

### Test Case 1: `css-grid-tutorial`

**A — Technical Correctness: 5/5**
All 8 keyframes present. 4 chapters properly structured. Brace balance perfect. All interactive element IDs resolve correctly.

**B — Design System Fidelity: 5/5**
All 7 required UI elements present: CSS variables, noise overlay, Google Fonts, sidebar, cursor glow, scroll progress, toast.

**C — Interactive Learning Elements: 4/5**
3 sandboxes across 4 chapters (one chapter missing its own sandbox), 3 quizzes, XP system, 3D tilt all present. Deduction: one chapter relies on sharing a sandbox rather than having a chapter-scoped one.

**D — Pedagogical Quality: 4/5**
All 3 quiz questions require conceptual application, not recall:
- Q1: *"What does `grid-template-columns: 1fr 2fr 1fr` create?"* — requires understanding the fr proportional distribution rule (L3)
- Q2: *"What does `grid-column: 1 / -1` do?"* — requires knowing negative line number semantics (L3)
- Q3: *"Key difference between `auto-fit` and `auto-fill`?"* — requires distinguishing two similar behaviors (L4)

Wrong-answer explanations teach the underlying model, not just the right answer. One-point deduction: the correct answer to Q2 ("makes the item span the full width") is stated near-verbatim in the explanation text above the quiz, making it partially guessable by scanning.

**Weighted total: 4.5/5** ✅

---

### Test Case 2: `goose-extensions-tutorial`

**A — Technical Correctness: 3/5**
7/8 keyframes (`confettiBurst` missing). 3 chapters present. Brace balance correct. Core JS functions work. Deduction for missing keyframe affecting correct-answer feedback animation.

**B — Design System Fidelity: 3/5**
6/7 required elements present; **sidebar is absent**. The sidebar is the primary navigation and chapter-progress element — its absence is a significant design regression, not a cosmetic one. All other elements (cursor glow, scroll progress, noise, toast, fonts) are present.

**C — Interactive Learning Elements: 2/5**
2 quizzes present, XP system present, 3D tilt present. **Zero code sandboxes** across 3 chapters. The spec requires ≥ 1 sandbox per chapter. For a tutorial about Goose extensions, a sandboxed YAML/config editor would be the natural teaching tool — its absence leaves the learner in passive reading mode for all technical content.

**D — Pedagogical Quality: 2/5**
Only 2 quiz questions:
- Q1: *"What protocol do Goose extensions use to communicate?"* — Answer is "MCP." This is pure recall; the word "MCP" appears repeatedly in the content directly above this quiz.
- Q2: *"When you toggle an extension in the per-session popup, what happens?"* — Closer to application (learner needs to reason about scope), but still answerable by scanning the preceding sentence.

Both questions are L1/L2. No question requires the learner to apply knowledge to a new scenario.

**Weighted total: 2.5/5** ❌ (fails on C and D; below 3.0 threshold)

---

### Test Case 3: `prototyping-process-tutorial`

**A — Technical Correctness: 5/5**
All 8 keyframes present. 5 chapters properly structured. Brace balance perfect. Full interactive JS architecture intact.

**B — Design System Fidelity: 5/5**
All 7 required UI elements present: CSS variables, noise overlay, Google Fonts, sidebar, cursor glow, scroll progress, toast.

**C — Interactive Learning Elements: 3/5**
5 quizzes across 5 chapters, XP system, and 3D card tilt all present. **Zero code sandboxes** — every chapter delivers content through widgets, cards, and quizzes, but none has a runnable sandbox. For a tutorial on the prototyping process, an interactive prompt-builder or output-diffing sandbox would be the natural teaching tool.

**D — Pedagogical Quality: 5/5**
All 5 quiz questions are scenario-based and require application, analysis, or evaluation:
- Q1: *"Your team wants to redesign the settings page. The PM has written detailed user stories... Which approach do you recommend?"* — application, requires weighing collaboration tradeoffs (L3)
- Q2: *"You have a screenshot of a competitor checkout flow... Which prompt produces the most useful prototype?"* — application, choosing the right prompting strategy (L3)
- Q3: *"You asked your AI tool to build a transaction categorization system. Its plan has 4 rules but no error handling... What is your best move?"* — analysis of system gaps (L4)
- Q4: *"You provided Claude with the Gemini 3 API documentation, but it keeps generating code using the old model name. What is the most effective fix?"* — application, debugging an AI context problem (L3)
- Q5: *"Gemini 3 Pro produces excellent one-shot code, but your project requires 20+ tool calls... What is your best strategy?"* — evaluation of model tradeoffs under constraints (L5)

No question is answerable by scanning nearby text. Wrong answers represent genuine misconceptions about AI-assisted prototyping.

**Weighted total: 4.5/5** ✅

---

## 7. Summary Results Table

| Test Case | A: Technical | B: Design | C: Interactive | D: Pedagogy | **Total** | Pass? |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| css-grid (TC1) | 5.0 | 5.0 | 4.0 | 4.0 | **4.5** | ✅ |
| goose-extensions (TC2) | 3.0 | 3.0 | 2.0 | 2.0 | **2.5** | ❌ |
| prototyping (TC3) | 5.0 | 5.0 | 3.0 | 5.0 | **4.5** | ✅ |

**Pass rate: 2/3 (67%)**

The failure in TC2 is concentrated in two dimensions — interactive elements (no sandboxes) and pedagogical quality (recall-level quizzes). TC3 shows that these two problems are separable: the prototyping tutorial has excellent quiz quality but the same sandbox gap.

Across the **6 scored real outputs**, the automated checks show:
- **3/6** (50%) have all 8 keyframes
- **5/6** (83%) have a sidebar
- **3/6** (50%) have code sandboxes
- **5/6** (83%) have quizzes
- **6/6** (100%) have balanced braces

---

## 8. Failure Analysis

### Failure 1: Code sandboxes systematically omitted (3/6 real outputs)

**Observed in**: vibe-coding, goose-extensions, prototyping-process
**Pattern**: Sandboxes are absent across both topic-mode and video-mode outputs. Crucially, the prototyping tutorial — which has near-perfect scores on every other dimension including Bloom's L3+ quizzes — still has zero sandboxes. This is not a quality-correlated failure; even strong outputs skip them.
**Root cause hypothesis**: When the agent cannot immediately map the topic to "obviously runnable code," it treats the sandbox as optional and skips it. For a Goose extensions tutorial, a YAML config sandbox would be natural. For a prototyping tutorial, a prompt-builder or split-screen output editor would work. But neither is "code" in the traditional sense, so the agent doesn't generate one.
**Impact**: Learners are locked into passive reading for those chapters. The sandbox is the primary "hands-on" element in the spec — without it, chapters are text + quiz, which is standard e-learning.
**Fix signal**: The spec should add explicit guidance: for non-code topics, the sandbox should be a structured input area relevant to the topic (config editor, prompt editor, pseudocode block). The agent should not have the option to skip it.

### Failure 2: `confettiBurst` keyframe missing in 50% of outputs

**Observed in**: goose-ai, vibe-coding, goose-extensions (3/6 real outputs)
**Pattern**: Consistently the *same* keyframe is missing. The other 7 keyframes are reliably present.
**Root cause hypothesis**: `confettiBurst` is used only for the "correct quiz answer" sparkle effect. When an agent generates a tutorial with few or no quizzes (or writes quizzes using a slightly different feedback pattern), it may omit this keyframe as "unused." The missing animation silently degrades the correct-answer experience without breaking anything.
**Impact**: Low functional impact (quiz still works), but the polish gap is real — confetti on correct answers is a documented part of the spec's delight layer.
**Fix signal**: Move `confettiBurst` into the "required keyframe block" that the agent copies verbatim before writing any chapter content.

### Failure 3: Video-mode quizzes test recall of specific video details, not applied understanding

**Observed in**: goose-workflow, goose-extensions, goose-ai (all video-mode outputs)
**Pattern**: Quiz questions in video-mode outputs tend to ask about specific facts mentioned in the transcript: what protocol, what directory, what UI suggestion was made. These are answerable only if you watched the video — or if you scan the tutorial text where the fact is restated.
**Concrete example** from `goose-workflow`:
> Q: "What UX improvement did the video suggest for Goose?"
> Correct: "Clickable file paths that open in your editor"

This is not an application question — it tests memory of a video detail. A learner who understands Goose deeply but didn't watch that specific video clip would get this wrong.
**Root cause hypothesis**: The pedagogical review step may not be running at full strength on video-derived content. The agent is grounding questions in the transcript (what was *said*) rather than in the learning objective (what should the learner be able to *do*).
**Impact**: High. This is the most educationally significant failure. The entire purpose of quizzes in the skill spec is to test applied understanding at Bloom's L3+.
**Fix signal**: The pedagogical review agent prompt should include an explicit check: *"Can this question be answered by someone who understands the concept but never watched this specific video? If no, rewrite it."*

### Reference: What a Stub Looks Like (`python-benefits-tutorial`)

This output was intentionally generated as a minimal quick prototype — not a full tutorialinator run — and is excluded from formal scoring. However, its structure is worth documenting because it clarifies what the hard-fail gates in Section 2 are designed to catch.

**Profile**: 10KB, 0 chapters, 0 keyframes, 0 sandboxes, 0 quizzes. The CSS variable block and noise overlay are present (template boilerplate), but the entire interactive architecture — sidebar, XP system, quiz engine, sandbox — is absent. The file opens in a browser and looks presentable at a glance: it has a large hero title, styled cards, and `<pre>` code blocks. A user who didn't know what to expect might not immediately realize they received a static article, not a tutorial.

**Why the hard-fail gates exist**: File size under 20KB, zero chapters, and zero keyframes are all individually sufficient to identify a stub. The gates ensure that if a production run ever produces output at this level of incompleteness — whether intentionally or due to a truncation event — the benchmark surfaces it explicitly rather than averaging it into aggregate scores.

---

## 9. Concrete Input/Output Examples

### Example A — Strong Quiz (css-grid-tutorial, Q3)

**Context**: Chapter 3 covers responsive grid patterns. The section above explains `auto-fill` and `auto-fit` with a diagram showing how each behaves when items don't fill a row.

**Quiz question produced:**
```
Q: What is the key difference between auto-fit and auto-fill?

A) auto-fit collapses empty tracks; auto-fill keeps them  ← correct
B) auto-fit only works with fr units; auto-fill works with any unit
C) auto-fill creates more columns; auto-fit creates fewer
D) There is no difference — they are aliases

Explanation: "auto-fit collapses empty tracks to zero width, so existing
items stretch to fill all available space. auto-fill keeps empty tracks at
their minimum width, which means items don't stretch when there's leftover
space. Both create the same number of columns when items fill the row."
```

**Why this works**: The answer is not in the preceding text verbatim — the learner must understand the distinction and select the correct consequence. Wrong answers represent real misconceptions (C is a common confusion). The explanation corrects both the wrong answers and deepens the right one.

---

### Example B — Weak Quiz (goose-extensions-tutorial, Q1)

**Context**: Chapter 1 introduces Goose extensions. The section directly above the quiz states: *"Goose extensions are MCP servers — they use the Model Context Protocol to communicate."*

**Quiz question produced:**
```
Q: What protocol do Goose extensions use to communicate?

A) REST API
B) Model Context Protocol (MCP)  ← correct
C) GraphQL
D) WebSockets

Explanation: "Goose extensions are MCP servers. MCP provides a standard
way for AI models to access external tools through Prompts, Resources,
and Tools."
```

**Why this fails**: The exact phrase "Model Context Protocol (MCP)" appears in the sentence immediately above this quiz. A learner who has not read the chapter at all can answer correctly in under 3 seconds by scrolling up. This tests reading, not understanding. A stronger question at L3:

```
Q: You want Goose to access your calendar and post updates to Slack.
   Which is the minimum correct setup?

A) Enable any extension — Goose routes requests automatically
B) Install two extensions: one for calendar, one for Slack  ← correct
C) Install one combined extension that handles all external services
D) No extensions needed — Goose has built-in web access
```

This requires the learner to apply the per-tool extension model to a new scenario.

---

### Example C — Strong Scenario Quiz (prototyping-process-tutorial, Q3)

**Context**: Chapter 3 covers AI-assisted system design. The section above explains that AI tools should be given explicit edge case requirements, not just happy-path specs.

**Quiz question produced:**
```
Q: You asked your AI tool to build a transaction categorization system.
   Its plan has 4 rules but no error handling for edge cases (unknown
   merchants, ambiguous categories). What is your best move?

A) Accept the plan — edge cases can be added later
B) Ask it to extend the plan with explicit error handling before coding  ← correct
C) Build it as-is and manually add error handling afterward
D) Switch to a different AI tool that handles edge cases automatically

Explanation: "Asking the AI to revise the plan before coding costs 2
minutes and prevents hours of refactoring. Once code is written, the AI's
context anchors to what exists — making it much harder to restructure for
edge cases. Front-load the design work."
```

**Why this works**: The question cannot be answered by scanning nearby text — it requires the learner to apply a design principle (plan before code) to a concrete debugging scenario. Wrong answers B and C both involve "adding error handling" but at different stages; distinguishing them requires understanding *why* the order matters, not just *what* to do.

---

## 10. Reproducibility

All 7 tutorial HTML files are at:
```
/Users/masud/css-grid-tutorial/src/tutorial.html
/Users/masud/goose-ai-tutorial/src/tutorial.html
/Users/masud/vibe-coding-tutorial/src/tutorial.html
/Users/masud/python-benefits-tutorial/src/tutorial.html
/Users/masud/goose-extensions-tutorial/src/tutorial.html
/Users/masud/goose-ai-workflow-automation-tutorial/src/tutorial.html
/Users/masud/prototyping-process-tutorial/src/tutorial.html
```

The automated checks in Section 5 can be reproduced by running `/tmp/validate.js` (written during this evaluation session) against each file:
```bash
node /tmp/validate.js /path/to/tutorial.html
```

Human rubric scoring in Sections 6–8 was performed by a single evaluator (author) using the anchors in Section 3. Bloom's level assignments for quiz questions were made using the standard taxonomy: L1 (recall), L2 (comprehension), L3 (application), L4 (analysis), L5 (evaluation).

`python-benefits-tutorial` is excluded from the formal test cases (intentional stub) but included in the automated check table and referenced in the failure analysis for the hard-fail gate discussion.

---

## 11. Benchmark Log

These tables are maintained by the tutorialinator agent itself. After every tutorial generation, the agent scores itself against the rubric in Section 3 and appends a row here — first after initial generation (One-Shot), then again after targeted refinement (Two-Shot).

**Columns**: Date · Topic · Mode · A (Technical) · B (Design) · C (Interactive) · D (Pedagogy) · Total · Notes

**Score key**: Each dimension is 1–5. Total is the unweighted average. Pass threshold: ≥ 3.5 overall, ≥ 3.0 on every dimension.

---

### One-Shot Benchmark

*Initial self-assessed score immediately after E2E tests pass, before any refinement.*

| Date | Topic | Mode | A | B | C | D | Total | Notes |
|------|-------|------|:-:|:-:|:-:|:-:|:-----:|-------|
| | | | | | | | | |

---

### Two-Shot Benchmark

*Self-assessed score after one targeted refinement pass. Column "Changed" describes what was improved.*

| Date | Topic | Mode | A | B | C | D | Total | Changed |
|------|-------|------|:-:|:-:|:-:|:-:|:-----:|---------|
| | | | | | | | | |
