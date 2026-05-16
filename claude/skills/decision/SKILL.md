---
name: decision
description: >
  Quick-scaffold a decision page in Projects/Work/<Client>/Decisions/ with today's
  date and the active client/project pulled from the per-machine hot cache.
  Triggers on: "/decision", "record this decision", "decision: <title>",
  "log a decision".
allowed-tools: Read Write Edit Glob Grep Bash
---

# decision: Quick decision scaffold

Captures a decision with rationale before the context is lost. A faster path than `/save decision` when you already know it's a decision.

Vault: `~/Documents/Obsidian/Notes/`. Decisions live in `Projects/Work/<Client>/Decisions/`.

---

## Workflow

1. **Detect machine** (`hostname -s` → label via `machines/<label>.md`).
2. **Read the per-machine hot cache** (`meta/hot - <machine>.md`) to get active client + project. If neither is set, ask the user.
3. **Get a title.** From CLI arg (`/decision <title>`) or ask.
4. **Pick the filename**: `Projects/Work/<Client>/Decisions/YYYY-MM-DD - <title>.md` (client is in the folder path, not the filename). Check existence; append `-2` (and warn) if collision.
5. **Scaffold from `Templates/claude-decision.md`** with frontmatter pre-filled:
   - `type: decision`
   - `client`, `project`, `machine`
   - `status: active`
   - `date`, `created`, `updated`: today
   - `tags: [decision]` + any client/project-specific tags
6. **Walk the user through the body** in order:
   - **Decision** (one sentence — what was decided)
   - **Context** (what forced it — link to the session that surfaced it)
   - **Options considered** (at least 2, ideally 3+, each with brief pros/cons)
   - **Why we picked this one** (rationale)
   - **Trade-offs accepted** (what we gave up)
   - **Revisit when** (specific triggers — not "in 6 months")
   - **Source** (link to the session)
7. **Update the project page** (`Projects/Work/<Client>/Plans/<Project>.md`) — add the new decision under `## Decisions`.
8. **Update the per-machine hot cache** — add the new decision under "Recent decisions" or "Open threads" if it has follow-ups.
9. **Prepend to `log.md`**:
   ```
   ## [YYYY-MM-DDTHH:MM <machine>] decision | <title>

   - Location: Projects/Work/<Client>/Decisions/<filename>.md
   - Client: [[Projects/Work/<Client>/_index|<Client>]]
   - Plan: [[Projects/Work/<Client>/Plans/<Project>|<Project>]]
   ```
10. **Confirm**: "Decision filed at [[Projects/Work/<Client>/Decisions/<filename>]]. Linked from the project page."

---

## Guardrails

- **Always capture alternatives.** A decision page without options considered is a bad decision page. If the user is stuck, prompt for at least one alternative.
- **Always capture trade-offs.** No decision is free; if the user says there's no trade-off, push back once.
- **Date is the decision date**, not always today. Ask if the decision was made earlier and is being recorded after-the-fact.

---

## Edge cases

- **Decision spans multiple projects.** Pick the primary project; cross-link from the others.
- **Decision is reversible.** Note this in `Trade-offs accepted` so future you doesn't over-weight the decision.
- **Decision supersedes a prior one.** Find the prior decision page, set its `status: superseded`, and link the new decision from it.
