---
description: Brief Claude on where work was left off, using the Obsidian wiki at ~/Documents/Obsidian/Notes/.
---

Read the `start` skill at `~/.claude/skills/start/SKILL.md` and run the cross-machine handoff workflow.

Usage:
- `/start` — read the per-machine hot cache, the cross-machine aggregator, and the most-recent session for the active client. Brief the user.
- `/start <client>` — same, but for a specific client (overrides the active client in hot).

Output should be scannable in 10 seconds: machine, active client/project, last session (date + machine), where you left off, local paths, quirks.
