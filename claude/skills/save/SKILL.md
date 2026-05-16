---
name: save
description: >
  File the current conversation into the Obsidian wiki at ~/Documents/Obsidian/Notes/.
  Determines note type (session / decision / source / scratchpad), creates the page in
  the correct folder with full frontmatter, updates the per-machine hot cache, and
  prepends an entry to log.md. Triggers on: "/save", "save this", "file this",
  "save to wiki", "save this session", "keep this".
allowed-tools: Read Write Edit Glob Grep Bash
---

# save: File the current conversation

This skill is purpose-built for a multi-client, multi-machine operational vault. It is not the marketplace `claude-obsidian:save` skill — the folder model differs.

Vault: `~/Documents/Obsidian/Notes/`. Per-client content lives under `Projects/Work/<Client>/<DocType>/`. Cross-client folders (`machines/`, `meta/`, `sources/`, `folds/`) sit at vault root. See the vault-root `CLAUDE.md` for the full structure and conventions.

---

## Note type decision

| Type | Folder | Use when |
|------|--------|---------|
| session | `Projects/Work/<Client>/Sessions/` | The conversation was a work session (default for general saves) |
| decision | `Projects/Work/<Client>/Decisions/` | An architectural / process / scoping decision was made with explicit alternatives |
| source | `sources/` | The conversation summarizes external material the user shared |
| scratchpad | `meta/` | Throwaway thinking or one-off notes that don't fit elsewhere |

If the user passed an explicit type (e.g. `/save decision <name>`), use that. Otherwise infer from content. If unclear, **ask once**.

---

## Naming

Filenames follow the vault convention. Since per-client content lives in `Projects/Work/<Client>/`, the client name is implicit in the folder and **not** in the filename:

- session: `Projects/Work/<Client>/Sessions/YYYY-MM-DD - <short topic>.md`
- decision: `Projects/Work/<Client>/Decisions/YYYY-MM-DD - <decision summary>.md`
- source: `sources/<slug>.md` (cross-client; slug from title)
- scratchpad: `meta/<YYYY-MM-DD> - <topic>.md`

If the user provided a name in `/save <name>`, use it for the topic. If a page with the same filename already exists, offer to update it instead of creating a duplicate.

---

## Machine identification

Run `hostname -s` to detect the current machine. Map to the documented label by reading `machines/<label>.md` frontmatter `hostname:` — find the page whose hostname matches and use its filename as the machine label. If no machine page exists, ask the user once for a short label and create the machine page from `Templates/claude-machine.md`.

`machine:` frontmatter is **required** for sessions, decisions, sources.

---

## Save workflow

1. **Detect machine** (`hostname -s` → map to label via `machines/`).
2. **Determine type** (CLI arg or content inference; ask if ambiguous).
3. **Determine client + project**: read the per-machine hot cache (`meta/hot - <machine>.md`) for the active client/project. If unclear or none active, ask.
4. **Pick a filename** per the naming rules above. Check existence; offer update-vs-duplicate if it exists.
5. **Create the note** from `Templates/claude-<type>.md`. Fill in:
   - frontmatter: `type`, `client`, `project`, `machine`, `created`, `updated`, `tags`, plus type-specific fields
   - body: declarative present-tense rewrite of the relevant conversation content (not "the user asked..."; the knowledge itself)
   - wikilinks for every mentioned client, project, session, decision, machine
6. **Update the per-machine hot cache** (`meta/hot - <machine>.md`): refresh `Currently Working On`, prepend the new session/decision/source to `Recent Sessions` / `Open Threads`, update `updated:` ISO timestamp. **Never touch other machines' hot caches.**
7. **Prepend to `log.md`** at the very top:
   ```
   ## [YYYY-MM-DDTHH:MM <machine>] save | <Note Title>

   - Type: <type>
   - Location: Projects/Work/<Client>/<Sessions|Decisions>/<Note Title>.md
   - Client: [[Projects/Work/<Client>/_index|<Client>]] (if applicable)
   - From: <one-line context>
   ```
   Use ISO local time (or UTC, but be consistent).
8. **Confirm** to the user: "Saved as [[Note Title]] in <folder>/. Hot cache for <machine> updated."

---

## Writing style

- Declarative present tense. Write the knowledge, not the conversation.
- Future sessions on a different machine should be able to read this page cold and understand.
- Link every mentioned concept, entity, or wiki page with `[[wikilinks]]`.
- Decision pages MUST capture: the decision, context, options considered (with brief pros/cons), why this one won, trade-offs accepted, revisit-when triggers.

---

## What to save vs. skip

Save:
- Non-obvious insights, decisions with rationale, analyses that took effort.
- Anything that future-Claude on another machine will need to pick up the thread.

Skip:
- Mechanical Q&A with obvious answers.
- Setup steps already in CLAUDE.md or machine pages.
- Anything already in the wiki — update the existing page instead.

---

## Multi-machine safety reminders

- Per-machine hot caches are exclusively owned. Read others, write only your own.
- All `_index.md` rosters are Dataview-driven. Don't add to them manually.
- `log.md` is the only commonly-written shared file. Always prepend, always include ISO timestamp + machine, so LiveSync conflict prompts (if surfaced) are trivial to resolve.
