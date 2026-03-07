# Progressive Disclosure: Case Studies and Lessons Learned

## Table of Contents

1. [Case Study 1: Over-Compression Failure](#case-study-1-over-compression-failure)
2. [Case Study 2: References Without Triggers](#case-study-2-references-without-triggers)
3. [Case Study 3: Code Patterns Moved to Level 2](#case-study-3-code-patterns-moved-to-level-2)
4. [Case Study 4: Trigger Index Buried in the Middle](#case-study-4-trigger-index-buried-in-the-middle)
5. [Case Study 5: Deleting Pre-Modification Checklist](#case-study-5-deleting-pre-modification-checklist)
6. [Case Study 6: No Information Recording Principles](#case-study-6-no-information-recording-principles)

---

## Case Study 1: Over-Compression Failure

**Scenario**: An Electron desktop app had a 2,937-line CLAUDE.md that was compressed to 165 lines. The intent was to follow the "under 200 lines" recommendation.

**What went wrong**: The compression removed:
- Native module lazy-load code patterns (the LLM re-derived them incorrectly)
- Error diagnostic flows (symptom -> cause -> fix chains were lost)
- Directory maps (the LLM couldn't find files and read the wrong ones)
- IPC communication patterns (the LLM invented incorrect channel naming)

**Root cause**: The optimizer conflated "minimize line count" with "maximize efficiency." These are different goals. A 482-line well-organized file with progressive disclosure outperforms a 165-line stripped file.

**Lesson**: Never compress below the information density threshold. If content is high-frequency (used in most sessions) or has severe consequences if violated, it stays in Level 1 regardless of line count. The 200-line guideline is a starting point, not a hard ceiling -- especially for complex projects.

**Resolution**: Restored to 482 lines with two-level architecture. Moved only the genuinely low-frequency content (historical decisions, detailed SOPs, edge cases) to Level 2.

---

## Case Study 2: References Without Triggers

**Scenario**: A web app's CLAUDE.md had 15 references to Level 2 documents, all formatted as bare links:
```
See deployment-sop.md
See database-patterns.md
See auth-flows.md
```

**What went wrong**: The LLM either:
- Ignored all references (most common) -- it didn't know when they were relevant
- Loaded all references at the start of every conversation (rare but expensive) -- treating them as mandatory reading

**Root cause**: Without a trigger condition, the LLM has no decision criteria. "See X" doesn't tell it *when* to see X. The reference becomes noise.

**Lesson**: Every reference needs two components:
1. **Trigger condition** -- the specific scenario that makes this reference relevant (an error message, a file being modified, a task being performed)
2. **Content summary** -- keywords describing what's inside, so the LLM can evaluate relevance without opening the file

**Resolution**: Replaced all bare links with trigger-condition format:
```markdown
**When to read `deployment-sop.md`**:
- Before deploying to staging or production
- When CI/CD pipeline fails
- When rotating secrets or environment variables

> Contains: per-environment runbooks, approval gates, rollback procedures
```

---

## Case Study 3: Code Patterns Moved to Level 2

**Scenario**: During optimization of a Node.js backend CLAUDE.md, all code examples were moved to `docs/references/code-patterns.md` to reduce Level 1 line count from 380 to 120 lines.

**What went wrong**: Every code-writing task now required the LLM to:
1. Recognize it needed a pattern
2. Open the Level 2 file
3. Find the right pattern
4. Copy it back into context

In practice, step 1 often failed -- the LLM would attempt to derive the pattern from memory rather than loading the reference. The derived patterns had subtle errors (wrong error handling, missing edge cases).

**Root cause**: Code patterns are high-frequency content. The LLM needs them available for direct copying on every code-writing task, not behind an extra read operation.

**Lesson**: Code patterns that are used frequently must stay in Level 1. The token cost of keeping them always-loaded is less than the error cost of re-derivation plus the latency cost of loading them on demand.

**Resolution**: Moved the 5 most-used code patterns back to Level 1. Kept the 12 less-common patterns in Level 2 with trigger conditions.

---

## Case Study 4: Trigger Index Buried in the Middle

**Scenario**: A CLAUDE.md had a single trigger index table placed at line 150 of a 300-line file, in a section labeled "Reference Documents."

**What went wrong**: In long conversations (10+ turns), the LLM stopped consulting the trigger index. When encountering errors that matched trigger conditions, it attempted to fix them from memory rather than loading the relevant Level 2 document.

**Root cause**: LLM attention follows a U-shaped curve (the "lost in the middle" phenomenon, Liu et al. 2023). Content at the beginning and end of context receives stronger attention than content in the middle. A single trigger index in the middle of the file falls into the attention trough.

**Lesson**: Place trigger indexes at **both** the top and bottom of the document:
- **Top (Reference Index)**: Establishes awareness at conversation start
- **Bottom (Reference Trigger Index)**: Serves as a reminder during long conversations when the beginning of context has been compressed

This is not duplication -- it's multiple entry points to the same resources, serving different user mindsets at different points in the conversation.

**Resolution**: Added a Reference Index table after the Information Recording Principles (top third) and a Reference Trigger Index table as the last section (bottom).

---

## Case Study 5: Deleting Pre-Modification Checklist

**Scenario**: During optimization, the "Pre-Modification Checklist" was removed because it was "redundant with the Reference Index." The reasoning was that both tables point to the same Level 2 documents.

**What went wrong**: The LLM stopped proactively checking for pitfalls before making changes. It would modify database schemas without checking migration procedures, change auth config without verifying session type updates, etc.

**Root cause**: The Reference Index and Pre-Modification Checklist serve different cognitive paths:
- **Reference Index** is reactive: "I hit an error -- where do I look?"
- **Pre-Modification Checklist** is proactive: "I'm about to change X -- what should I watch for?"

Removing the proactive path meant the LLM only consulted references after breaking something, not before.

**Lesson**: The three entry points (Reference Index, Pre-Modification Checklist, Reference Trigger Index) each serve a different user mindset. Removing any one of them creates a gap in the LLM's decision-making process.

**Resolution**: Restored the Pre-Modification Checklist as a dedicated table indexed by "what you're changing" rather than "what error you hit."

---

## Case Study 6: No Information Recording Principles

**Scenario**: A CLAUDE.md was optimized with progressive disclosure -- Level 1 was clean, Level 2 references were well-structured. Two weeks later, the file had grown from 200 lines back to 450 lines.

**What went wrong**: Users kept asking Claude to "remember this" or "add this to CLAUDE.md." Without guidance on where to put new information, Claude defaulted to adding everything to Level 1. The file re-bloated with:
- Detailed debugging notes that should have been Level 2
- Full configuration examples that should have been Level 2
- Historical decision records that should have been Level 2

**Root cause**: Progressive disclosure is not just a one-time reorganization -- it's an ongoing information routing system. Without explicit routing rules, new information always flows to the path of least resistance (Level 1).

**Lesson**: The "Information Recording Principles" section is the most important structural element. It makes the LLM self-governing by providing explicit routing rules:
- High-frequency -> Level 1
- Detailed/low-frequency -> Level 2
- Level 1 references to Level 2 require trigger condition + content summary

Without this section, any optimization will regress within weeks.

**Resolution**: Added Information Recording Principles as the first section after the project overview. Re-bloat stopped immediately.

---

## Information Density Standards

### Optimal Level 1 Density

| Dimension | Target |
|---|---|
| Total lines | 200-400 (project-level), 100-200 (user-level) |
| Commands | Complete table, no need to ask |
| Hard rules | Each with WRONG/RIGHT code block |
| Error diagnostics | Top 5-8 most common, complete flow |
| Code patterns | Top 3-5 most used, copy-paste ready |
| Directory map | Feature -> file, fits in one table |
| Trigger indexes | At top and bottom |

### Signs of Under-Information

- LLM asks the same clarifying question across multiple sessions
- LLM re-derives code patterns from scratch (inventing slightly wrong versions)
- User has to correct the LLM repeatedly on the same rules

### Signs of Over-Information

- Level 1 contains step-by-step workflows for rare operations
- Same content appears verbatim in multiple sections (not multiple entry points -- actual duplication)
- Edge cases intermixed with common cases in the same section
- Historical context ("we used to do X but switched to Y because...") in Level 1

---

## Level 1 Retention Checklist

Before moving any content to Level 2, verify it's not in this list:

- [ ] Core commands (high frequency -- must always be visible)
- [ ] Hard rules with code examples (severe consequences -- must always be visible)
- [ ] Error diagnostic flows for the top 5-8 errors (high frequency + saves debugging time)
- [ ] Copy-paste code patterns for the 3-5 most common tasks (prevents re-derivation errors)
- [ ] Directory/structure map (saves file-finding time every session)
- [ ] Trigger index tables (must be visible at top and bottom)
- [ ] Pre-modification checklist (proactive pitfall prevention)

If content is on this list, it stays in Level 1 regardless of line count.
