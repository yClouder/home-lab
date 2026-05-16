---
name: ingest
description: >
  Ingest an external source (URL or local file) into the vault as a sources/<slug>.md
  page with a summary, key takeaways, and frontmatter linking it to the active
  client/project. URLs are fetched via Defuddle for clean markdown. Triggers on:
  "/ingest", "ingest this url", "save this article", "add this source",
  "process this".
allowed-tools: Read Write Edit Glob Grep Bash WebFetch
---

# ingest: Source -> sources/

Pull an external source into the vault as a durable summary page.

Vault: `~/Documents/Obsidian/Notes/`. See vault-root `CLAUDE.md` for conventions.

---

## Inputs

The skill accepts:
- A URL (http/https) — fetch via Defuddle (`obsidian:defuddle`) for clean markdown; fall back to WebFetch if Defuddle is unavailable.
- A local path — read directly. Common types: `.md`, `.txt`, `.pdf` (call `pdftotext` via Bash for PDFs).
- A file already in `.raw/` — read directly.

---

## Workflow

1. **Detect machine** (`hostname -s` → `machines/<label>.md`).
2. **Determine source type** (URL / local path / .raw entry).
3. **Fetch / read the content.**
   - URL: prefer Defuddle. If the URL ends in `.md`, use WebFetch directly. Save the raw cleaned markdown to `.raw/<slug>-<date>.md` for provenance.
   - Local file: copy or symlink the original into `.raw/` if not already there. PDFs: extract text to `.raw/<slug>-<date>.txt`.
4. **Generate a slug** from the title (lowercase, hyphenated, no special chars). Check `sources/<slug>.md` doesn't already exist; append `-2` etc. if needed (and warn the user).
5. **Read the active client / project** from this machine's hot cache (`meta/hot - <machine>.md`). If unclear, ask.
6. **Create `sources/<slug>.md`** from `Templates/claude-source.md`:
   - frontmatter: `type: source`, `title`, `source_url` (or `source_path`), `client`, `project`, `machine`, `ingested` (today), `created`, `updated`, `status: active`, `tags`
   - body: 2-4 sentence summary, 3-7 key takeaways, 1-3 quotes worth keeping, related wikilinks, pointer to the `.raw/` original
7. **Update the client page** (or project page if more specific) to reference the new source under a "Sources" or "References" section.
8. **Update the per-machine hot cache** — add this source under a "Recently Ingested" line.
9. **Prepend to `log.md`** at the top:
   ```
   ## [YYYY-MM-DDTHH:MM <machine>] ingest | <slug>

   - Source: <url or path>
   - Saved: sources/<slug>.md
   - Raw: .raw/<slug>-<date>.<ext>
   - Client: [[Projects/Work/<Client>/_index|<Client>]]
   ```
10. **Confirm**: "Ingested [[sources/<slug>]] from <source>. Raw saved at <path>."

---

## Summarization rules

- Declarative present tense; capture the **claims and findings**, not the writing style.
- Quote 1-3 passages that are likely to be cited later, no more.
- If the source contradicts something already in the wiki, flag it in the body with `> [!warning] Contradicts [[Page]]: <details>`.
- If the source is paywalled / time-limited (news, login-required), capture more aggressively — the original may disappear.

---

## Skip if

- The same URL is already in `sources/`. Offer to update the existing page instead.
- The content is generic (Wikipedia overview of a well-known topic) and not needed for any active project.

---

## Multi-machine notes

- `.raw/` is immutable. Once written, never modify. If a second machine ingests the same URL, it can re-fetch into a new `.raw/<slug>-<date2>.md`; the latter is the newer copy.
- `sources/<slug>.md` is write-once per slug. If both machines try to ingest concurrently, LiveSync will surface a conflict — resolve by picking one summary and updating it.
