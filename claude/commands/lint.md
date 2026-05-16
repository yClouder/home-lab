---
description: Health-check the Obsidian wiki — find orphans, dead links, frontmatter gaps, stale tasks, LiveSync conflict markers.
---

Read the `lint` skill at `~/.claude/skills/lint/SKILL.md` and run the wiki health check.

Usage:
- `/lint` — full health check, write report to `meta/lint-YYYY-MM-DD.md`, summarize top issues
- `/lint fix` — same, then prompt to auto-fix the trivial findings (one at a time)

Read-only by default. Never modifies hot caches owned by other machines. Never touches `.raw/`.
