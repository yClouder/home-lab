---
name: start
description: >
  Brief Claude on where work was left off. Reads the per-machine hot cache, the
  cross-machine aggregator, and the most-recent session for the active client.
  Use at the start of a session, especially after switching machines. Triggers on:
  "/start", "where was I", "pick up where I left off", "what was I doing", "resume".
allowed-tools: Read Glob Grep Bash
---

# start: Cross-machine session handoff

Read the vault state and present a tight brief so the user (and you) can resume work.

Vault: `~/Documents/Obsidian Vault/`. See vault-root `CLAUDE.md` for conventions.

---

## Workflow

1. **Detect machine.** Run `hostname -s` and map to a `machines/<label>.md` via frontmatter `hostname:`. If no match, note this and continue with the bare hostname.

2. **Read this machine's hot cache.** `meta/hot - <machine>.md`. Capture: active client, project, recent sessions, open threads, cross-machine notes.

3. **Read the cross-machine hot aggregator.** `meta/hot.md`. The Dataview tables tell you what other machines wrote recently — useful if you switched machines and the local hot is stale.

4. **Identify the active client / project.** From this machine's hot cache. If ambiguous, ask the user.

5. **Read the most-recent session for that client.** Glob `Projects/Work/<Client>/Sessions/` for files matching `* - <Client> - *.md`, pick the lexicographically latest (date prefix). Read its `## Next session should` and `## Blockers / open threads` blocks.

6. **Read the client and project pages.** `Projects/Work/<Client>/_index.md`, `Projects/Work/<Client>/Plans/<Project>.md`. Capture status, open questions, files/paths.

7. **Read the machine page.** `machines/<machine>.md`. Capture local paths and quirks for the active client.

8. **Brief the user** in this format:

   ```
   ## You're on: <machine>
   ## Active: <Client> / <Project>
   ## Last session (on <last-machine>): <date> — <topic>
   ## Where you left off
   - <pulled from "Next session should">
   - <pulled from "Blockers">
   ## Local paths on this machine
   - <repo>: <path>
   ## Quirks to remember
   - <from machine page + client conventions>
   ```

9. **Wait** for the user's first directive. Don't act on the brief — just deliver it.

---

## Edge cases

- **No hot cache for this machine yet.** Note it and offer to bootstrap one (read latest session globally, then create `meta/hot - <machine>.md` from `Templates/claude-`).
- **No active client / project in hot.** Ask the user which client they want to work on, then read accordingly.
- **Stale cross-machine state.** If the most-recent session globally is on a different machine, surface that fact: "Last work was on `<other-machine>` (<date>). This machine's hot may be stale."
- **LiveSync conflict markers in a hot cache.** Surface immediately and ask the user how to resolve before continuing.

---

## Output discipline

The brief should be scannable in 10 seconds. Use short bullets, ISO dates, repo paths. Don't paraphrase the session log — quote the bits the user actually needs.
