---
name: fold
description: >
  Roll up the last 2^k entries from log.md into a fold page in folds/.
  Extractive summarization only — no invention. Idempotent on filename. Triggers on:
  "/fold", "fold the log", "rollup log", "log fold", "compress log".
allowed-tools: Read Write Edit Glob Grep Bash
---

# fold: Log rollup

Periodic compression of `log.md` entries into a single fold page that links back to its children. Inspired by DragonScale Memory's mechanism 1 (flat fold over raw log entries).

Vault: `~/Documents/Obsidian/Notes/`. Folds live in `folds/`.

---

## When to fold

When `log.md` exceeds ~50 top-level entries, fold the older half. Pick `k` so `2^k` matches a clean break — typically k=3 (8 entries), k=4 (16), or k=5 (32).

---

## Filename convention

```
folds/fold-k{n}-{from-date}-to-{to-date}-n{count}.md
```

Example: `fold-k3-from-2026-05-01-to-2026-05-08-n8.md`.

If the file already exists, this is a **no-op** (the same range has been folded before). Report and stop. Re-folding requires `--force` (and the user must say so explicitly).

---

## Workflow

1. **Detect machine** (`hostname -s` → label).
2. **Determine the range to fold.**
   - Default: count `log.md` entries (`grep -c "^## \[" log.md`), pick the oldest `2^k` entries for some k (ask the user which k if ambiguous).
   - From the chosen entries, extract `from_date` (oldest) and `to_date` (newest).
3. **Compute the fold id**: `fold-k{n}-from-{from-date}-to-{to-date}-n{count}`.
4. **Check existence**: if `folds/<fold_id>.md` already exists, stop and report. Don't overwrite without `--force`.
5. **Extract structured info** from each entry: the operation type (save/ingest/lint), the affected page, the client, the machine. Stay extractive — quote the entries; don't invent.
6. **Write the fold page** from `Templates/claude-fold.md`:
   - frontmatter: `type: fold`, `fold_id`, `k`, `entry_count`, `from_date`, `to_date`, `created`, `updated`, `tags: [fold]`
   - body: by-client breakdown, by-machine breakdown, decisions made in this window (with wikilinks), and a "Source entries" list linking each child entry back to its location in `log.md` (use the entry header text).
7. **Update `log.md`**:
   - Remove the folded entries (the ones now linked from the fold page).
   - Prepend a single new entry summarizing the fold:
     ```
     ## [YYYY-MM-DDTHH:MM <machine>] fold | <fold_id>

     - Folded: N entries from <from-date> to <to-date>
     - Location: folds/<fold_id>.md
     ```
8. **Confirm**: "Folded N entries into [[folds/<fold_id>]]. log.md shrunk from X to Y entries."

---

## Idempotency

Same `(k, from-date, to-date)` always produces the same `fold_id`. The filename is the idempotency token: if it already exists, do nothing. LLM prose may vary across runs, but the filename and scope are deterministic.

Do NOT regenerate fold content unless the user explicitly requests `--force`.

---

## What NOT to do

- Don't fold-of-folds (no hierarchical level-stacking). One pass per fold.
- Don't modify hot caches.
- Don't touch `.raw/`.
- Don't invent content — extractive only. If something needs interpretation, link to the source entry instead.
- Don't fold the latest entries — always leave the most recent ~16 in `log.md` for quick browsing.

---

## Multi-machine notes

Folds are write-once per filename, so concurrent folds across machines on the same range collide on the filename and one machine wins per LiveSync conflict resolution. To minimize this, fold at most weekly and only after a deliberate review.
