# Progressive Disclosure Plugin

Organize any LLM-consumed document using three-tier progressive disclosure (lazy prompting). Keeps high-signal content always loaded, defers low-frequency detail to on-demand files.

## Installation

Add to your Claude Code plugins:

```bash
claude plugin add /path/to/progressive-disclosure
```

Or install from the marketplace.

## Usage

### Slash Command

```
/progressive-disclosure
```

Runs an interactive workflow that:
1. Detects the target document (CLAUDE.md, AGENTS.md, system prompts, etc.)
2. Classifies each section into three tiers (always loaded, conditional, on-demand)
3. Proposes file moves with user approval at each step
4. Adds structural elements (Reference Index, Pre-Modification Checklist, etc.)
5. Verifies all references resolve

### Auto-Suggestion Hook

When you edit a target document past a line threshold (200 for project-level, 100 for user-level), the plugin suggests running `/progressive-disclosure`.

### Configuring Target Documents

Edit `config/targets.txt` to add custom glob patterns:

```
*/CLAUDE.md
*/.claude/CLAUDE.md
*/AGENTS.md
*/system-prompt.md
docs/runbook-*.md
```

## Three-Tier Architecture

| Tier | When Loaded | Examples |
|---|---|---|
| **Level 1** | Every session | Core commands, hard rules, code patterns, error diagnostics |
| **Level 1.5** | When conditions match | `.claude/rules/` (CLAUDE.md), conditional sub-docs (AGENTS.md) |
| **Level 2** | On demand via trigger | SOPs, edge cases, historical decisions, full config examples |

## Companion Skills

- `/revise-claude-md` (from `claude-md-management` plugin) — routes new learnings to the correct tier, preventing re-bloat

## Keywords

progressive-disclosure, lazy-prompting, progressive-discovery, claude-md, agents-md, optimization
