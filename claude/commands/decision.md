---
description: Quick-scaffold a decision page in Projects/Work/<Client>/Decisions/ with today's date and the active client/project.
---

Read the `decision` skill at `~/.claude/skills/decision/SKILL.md` and run the decision-scaffold workflow.

Usage:
- `/decision <title>` — scaffold `Projects/Work/<Client>/Decisions/YYYY-MM-DD - <title>.md` and walk the user through filling it
- `/decision` (no arg) — prompt for the title first

The skill pulls active client/project from this machine's hot cache, pre-fills frontmatter (`machine`, `client`, `project`, `status: active`), and prompts for: Decision, Context, Options considered, Why we picked this one, Trade-offs accepted, Revisit when. Updates the project page's `## Decisions` section, the per-machine hot cache, and `log.md`.

Always demands at least 2 alternatives and at least one trade-off. Pushes back if the user says there's no trade-off.
