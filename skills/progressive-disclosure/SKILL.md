---
name: progressive-disclosure
description: |
  Organize any LLM-consumed document using three-tier progressive disclosure (lazy prompting).
  Goal: Maximize LLM working efficiency, NOT minimize line count.
  Applicable to CLAUDE.md, AGENTS.md, system prompts, runbooks, and any document an LLM reads at session start.
  Uses three tiers: Level 1 (always loaded), Level 1.5 (path-scoped or conditional), and Level 2 (on-demand via trigger conditions).
  MUST use this skill when the user:
  - Says "/progressive-disclosure", "optimize my instructions", "reorganize my docs"
  - Wants to optimize, reorganize, restructure, or shrink their CLAUDE.md, AGENTS.md, or system prompt
  - Complains the LLM ignores rules, forgets conventions, or keeps making the same mistakes
  - Has a document over 200 lines that has grown unwieldy
  - Mentions "progressive disclosure", "lazy prompting", "progressive discovery", "three-tier"
  - Says things like "my instructions are too long", "Claude isn't following my rules", "context window is filling up", "reduce my prompt size", "organize my project instructions"
  - Wants to move detailed SOPs, deployment runbooks, or reference docs out of their main instructions while keeping them accessible
  - Asks how to structure LLM instructions so they scale as the project grows
  Even if the user doesn't mention progressive disclosure by name, use this skill whenever the core problem is "instructions are too long or ineffective" or "the LLM doesn't follow my instructions consistently."
user_invocable: true
---

# Progressive Disclosure

## Overview

A general methodology for organizing any document an LLM consumes — CLAUDE.md, AGENTS.md, system prompts, runbooks, or any instruction file loaded into context. The core principle: keep high-signal content always loaded, defer low-frequency detail to on-demand files.

Also known as: **lazy prompting** (Teresa Torres), **progressive discovery**.

**Complementary skill**: After optimizing, use `/revise-claude-md` (from `claude-md-management` plugin) to capture future learnings into the right tier — it prevents re-bloat by routing new information appropriately.

---

## Interactive Workflow

### Step 0: Detect Target

Determine which document(s) to optimize:

1. Ask the user which document to optimize, or auto-detect common targets:
   - Project CLAUDE.md: `./CLAUDE.md` or `./.claude/CLAUDE.md`
   - User CLAUDE.md: `~/.claude/CLAUDE.md`
   - AGENTS.md: `./AGENTS.md`
   - System prompts or other instruction files the user specifies
2. Show file path and line count

**ASK USER**: "Found `{path}` ({N} lines). Optimize this file? Or specify a different document."

### Step 1: Back Up

Create a timestamped backup before making any changes:

```bash
cp {target} {target}.bak.$(date +%Y%m%d_%H%M%S)
```

Confirm backup was created.

### Step 2: Analyze & Classify

Read the entire file. For each section, apply the classification decision tree:

| Question | Yes | No |
|---|---|---|
| Used frequently (most sessions)? | Level 1 | next question |
| Severe consequences if violated? | Level 1 | next question |
| Contains code patterns for direct copying? | Level 1 (keep the pattern) | next question |
| Scoped to specific file paths or conditions? | Level 1.5 | next question |
| Has a clear trigger condition? | Level 2 + trigger in Level 1 | next question |
| Historical or reference material? | Level 2 | Consider removing |

**Level 1.5 depends on document type:**
- **CLAUDE.md** → `.claude/rules/` files with `paths:` frontmatter (Anthropic's native lazy loading)
- **AGENTS.md** → conditional sections or linked sub-agent docs
- **System prompts** → conditional includes or modular prompt segments
- **Other docs** → sub-documents, appendices, or linked references

Present a classification table:

| Section | Lines | Tier | Reason |
|---|---|---|---|
| (section name) | (count) | L1 / L1.5 / L2 | (brief justification) |

Show summary: "X lines staying in L1, Y lines moving to L1.5, Z lines moving to L2"

**ASK USER**: "Does this classification look right? Want to adjust any rows before I proceed?"

### Step 3: Propose Level 1.5 Moves

For each section classified as Level 1.5, propose the destination based on document type:

**For CLAUDE.md** — `.claude/rules/` files:
```
File: .claude/rules/{domain}.md
---
paths:
  - "{matching-glob-pattern}"
---
{content to move}
```

**For AGENTS.md** — conditional sub-documents:
```
File: docs/agents/{topic}.md
Activation: When agent handles {specific task type}
```

**For other documents** — linked sub-documents:
```
File: {doc-root}/{topic}.md
Include condition: {when this section is relevant}
```

**ASK USER**: "Create these files? Approve, adjust, or skip any."

### Step 4: Propose Level 2 Moves

For each section classified as Level 2, show the proposed reference file:

```
File: {references-dir}/{topic}-reference.md
Trigger condition: {when this file should be loaded}
Content summary: {keywords describing what's inside}
```

**References directory depends on document type:**
- CLAUDE.md → `docs/references/`
- User-level CLAUDE.md → `~/.claude/references/`
- Other documents → `{doc-root}/references/` or co-located

**ASK USER**: "Create these reference files? Approve, adjust, or skip any."

### Step 5: Generate Structural Additions

Preview each structural element to add to the optimized document:

1. **Information Recording Principles** (near top) — self-governing rules that prevent re-bloat by routing new information to the correct tier
2. **Reference Index** (top section) — problem-triggered lookup: "I hit an issue — where do I look?"
3. **Pre-Modification Checklist** (middle section) — proactive lookup: "I'm about to change X — what should I watch for?"
4. **Reference Trigger Index** (bottom section) — reminder during long conversations (addresses the "lost in the middle" attention curve)

Show a preview of each element populated with the document's actual references.

**ASK USER**: "Add all structural elements, or skip any?"

### Step 6: Apply Changes

Execute the approved changes:

1. Create Level 1.5 files (`.claude/rules/`, sub-documents, etc.)
2. Create Level 2 reference files
3. Rewrite the target document: remove moved sections, add approved structural elements
4. Show a diff summary of what changed

### Step 7: Verify

Run verification checks:

- Confirm all referenced files exist on disk
- Report: "Before: {N} lines. After: {M} lines. {K} files at Level 1.5, {J} files at Level 2."

### Step 8: Next Steps

- For CLAUDE.md: use `/revise-claude-md` (from `claude-md-management` plugin) to capture future learnings — it routes new information to the correct tier automatically
- The Information Recording Principles section makes the LLM self-governing: when asked to "remember this," it routes to L1, L1.5, or L2 based on frequency and scope
- Re-run `/progressive-disclosure` periodically if the file grows past the target line count again

---

## Progressive Disclosure Principles (Reference)

> The content below serves as background reference. It activates when trigger conditions match outside of explicit `/progressive-disclosure` invocation.

### Core Philosophy

> "Find the smallest set of high-signal tokens that maximizes the probability of the desired outcome." — Anthropic

**The goal is to maximize LLM working efficiency, not to minimize line count.**

Documents accumulate knowledge — SOPs, diagnostics, code patterns, edge cases — that often pushes past manageable sizes. Progressive disclosure solves this tension: keep high-signal content in Level 1 (always loaded) and move detailed reference material to Level 2 (loaded on demand when triggered).

### Three-Tier Architecture

```
Level 1 (Primary Document) — Loaded every session
+-- Information Recording Principles   <- Self-governing rules to prevent future bloat
+-- Reference Index (top)              <- Entry 1: "I hit an error -- where do I look?"
+-- Core content (commands, rules, patterns)
+-- Pre-modification checklist          <- Entry 2: "I'm about to change X -- watch for what?"
+-- Reference Trigger Index (bottom)    <- Entry 3: reminder after long conversations

Level 1.5 (Conditional Loading) — Loaded when conditions match
  For CLAUDE.md:  .claude/rules/ with paths: frontmatter (Anthropic's native lazy loading)
  For AGENTS.md:  conditional sub-agent docs
  For other docs: modular sections, conditional includes

Level 2 (On-Demand) — Loaded via explicit trigger
+-- Detailed SOP workflows
+-- Edge case handling
+-- Full configuration examples
+-- Historical decision records
```

**Level 1.5 is the most underused mechanism.** For CLAUDE.md, `.claude/rules/` files with `paths:` frontmatter load automatically when the LLM touches matching files — zero token cost otherwise. For other document types, equivalent conditional-loading mechanisms exist.

### The Multi-Entry Principle

A single Level 2 resource can have **multiple entry points** that serve different lookup paths:

| Entry Point | Position | Trigger Scenario | User Mindset |
|---|---|---|---|
| Reference Index | Top | Hit an error or problem | "Something broke — which doc should I read?" |
| Pre-modification checklist | Middle | About to change code | "I'm changing X — what pitfalls exist?" |
| Reference Trigger Index | Bottom | Orientation during long conversation | "What was that reference doc again?" |

**This is not duplication — it's multiple entry points.** Like a book having a table of contents (by chapter), an index (by keyword), and a quick-reference card (by task).

The reason this matters: LLM attention follows a U-shaped curve — the beginning and end of context receive stronger attention than the middle (the "lost in the middle" phenomenon). Placing trigger indexes at both top and bottom ensures they're noticed regardless of conversation length.

### Classification Decision Tree

For each section, ask these questions in order:

| Question | Yes | No |
|---|---|---|
| Used frequently? | Level 1 | next question |
| Severe consequences if violated? | Level 1 | next question |
| Contains code patterns that need direct copying? | Level 1 (keep the pattern) | next question |
| Scoped to specific file paths or conditions? | Level 1.5 | next question |
| Has a clear trigger condition? | Level 2 + trigger in Level 1 | next question |
| Historical or reference material? | Level 2 | Consider removing |

### Content Retention Rules (what stays in L1)

| Content Type | Reason |
|---|---|
| **Core commands** | High-frequency use |
| **Hard rules / prohibitions** | Severe consequences if violated — must always be visible |
| **Code patterns** | LLM needs to copy directly; avoids re-derivation |
| **Error diagnostics** | Complete symptom -> cause -> fix flow |
| **Directory/structure map** | Helps LLM locate files quickly |
| **Trigger index tables** | Helps LLM find Level 2 during long conversations |

### What Moves to Level 2

| Content Type | Level 1 keeps | Level 2 gets |
|---|---|---|
| SOP workflows | Trigger condition + key pitfalls | Full step-by-step |
| Config examples | The 1-2 most common | Complete configuration |
| API documentation | Common method signatures | Full parameter reference |
| Historical decisions | Nothing (or a one-liner) | Full rationale |
| Performance data | Nothing | Full benchmarks |
| Edge cases | Nothing | Detailed handling |

### Reference Formats (4 varieties)

Use a mix of these formats — variety helps the LLM distinguish different types of references.

**1. Detailed Format** (important in-body references):
```markdown
**When to read `{references-dir}/xxx-sop.md`**:
- [specific error message]
- [specific scenario]

> Contains: [keyword 1], [keyword 2], [code template].
```

**2. Problem Trigger Table** (top/bottom index):
```markdown
## Reference Index
| Trigger | Document | Key Content |
|---|---|---|
| `ERR_DLOPEN_FAILED` | `native-modules-sop.md` | ABI mechanism, lazy loading |
```

**3. Task Trigger Table** (pre-modification checklist):
```markdown
## Pre-Modification Checklist
| What you're changing | Read this first | Key pitfalls |
|---|---|---|
| Native module code | `native-modules-sop.md` | Must lazy-load |
```

**4. Inline Format** (brief references):
```markdown
Full workflow in `database-sop.md` (FTS5 escaping, health checks).
```

### Anti-Patterns

| Anti-Pattern | Example | Fix |
|---|---|---|
| **Over-Compression** | 2,937 lines compressed to 165 | Keep all high-frequency content; 482 organized lines beats 165 stripped lines |
| **References Without Triggers** | `See xxx.md` | Always pair with trigger condition + content summary |
| **Code Patterns in Level 2** | Moving frequently-used code examples to reference files | High-frequency code patterns stay in Level 1 |
| **Deleting Instead of Moving** | Removing "unimportant" sections entirely | Move to Level 2 with a trigger; never delete knowledge |

### Information Density Checks

| Check | Passing Criteria |
|---|---|
| Daily commands | No need to read Level 2 |
| Common errors | Has complete diagnostic flow |
| Code writing | Has copy-paste patterns |
| Specific problems | Knows which Level 2 to read |
| Trigger indexes | Table format at top and bottom |

**Too little**: LLM repeatedly asks same questions, re-derives patterns, user corrects same rules.
**Too much**: Low-frequency workflows in Level 1, identical content duplicated (not multi-entry), edge cases mixed with common cases.

### Document-Specific Guidelines

| Dimension | User-Level CLAUDE.md | Project-Level CLAUDE.md | AGENTS.md | Other Docs |
|---|---|---|---|---|
| Target L1 lines | 100-200 | 200-400 | 150-300 | Varies |
| L1.5 mechanism | `~/.claude/rules/` | `.claude/rules/` | Sub-agent docs | Conditional includes |
| L2 location | `~/.claude/references/` | `docs/references/` | `docs/agents/` | Co-located `references/` |
| Shares with | Just you | Team via source control | Team | Depends on doc |

### Quick Checklist

After optimizing, verify:

- [ ] **"Information Recording Principles" near the top** (prevents future bloat)
- [ ] **Reference Index near the top** (Entry 1: problem-triggered lookup)
- [ ] Core content is complete (commands, rules, patterns)
- [ ] Hard rules / prohibitions include WRONG/RIGHT examples (not just prose)
- [ ] Common errors have complete diagnostic flow (symptom -> cause -> fix)
- [ ] Code patterns are copy-paste ready
- [ ] **Level 1.5 files** created for path-scoped or conditional content
- [ ] **"Pre-Modification Checklist" table** (Entry 2: indexed by "what you're changing")
- [ ] **Reference Trigger Index near the bottom** (Entry 3: reminder in long conversations)
- [ ] Every Level 2 reference has a trigger condition
- [ ] All referenced files exist on disk

For detailed case studies and lessons learned, see `references/progressive-disclosure-principles.md`.
