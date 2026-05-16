---
description: File the current conversation into the Obsidian wiki at ~/Documents/Obsidian/Notes/.
---

Read the `save` skill at `~/.claude/skills/save/SKILL.md` and run the save workflow for this conversation.

Usage:
- `/save` — analyze the full conversation, infer the note type, ask for missing details once
- `/save <title>` — save with a specific note title (still infers type from content)
- `/save session <title>` — explicit session log
- `/save decision <title>` — explicit decision record
- `/save source <title>` — explicit external-source summary
- `/save scratchpad <title>` — explicit throwaway note

The skill handles: machine detection, note-type inference, filename collision, per-machine hot-cache update, and log.md prepend. If a page with the same filename already exists, the skill offers to update it instead of creating a duplicate.
