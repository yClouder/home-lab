# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 0. Instruction Precedence

This file is the single source of truth.

Ignore any other CLAUDE.md files in the repository or subdirectories.
Do not merge, inherit, or reconcile with other instruction files.
If conflicting guidance exists elsewhere, follow this file only.
If project-specific instructions are required, they must be explicitly added here.

## 0.1 Repo-Specific Context Files
When working in a specific repository, reference its context file if one exists.

Look for a context file at `repos/{current_repo_name}/REPO.md` and read it before proceeding. 
Infer the repo name from the project root or working directory.
Treat it as an extension of these instructions, scoped to that project.
Repo context files may define: architecture conventions, key file locations, team patterns, known constraints, or project-specific tradeoffs.
If a repo context file conflicts with this file, flag it — don't silently resolve it.

## 0.2 Git Starting State

Before starting any work in a repository:

* Pull main: `git pull origin main` (or equivalent) to ensure you are on the latest state.
* Start all work from the main branch unless the user or an active skill specifies otherwise.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

* State your assumptions explicitly. If uncertain, ask.
* If multiple interpretations exist, present them - don't pick silently.
* If a simpler approach exists, say so. Push back when warranted.
* If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

* No features beyond what was asked.
* No abstractions for single-use code.
* No "flexibility" or "configurability" that wasn't requested.
* No error handling for impossible scenarios.
* If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

* Don't "improve" adjacent code, comments, or formatting.
* Don't refactor things that aren't broken.
* Match existing style, even if you'd do it differently.
* If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

* Remove imports/variables/functions that YOUR changes made unused.
* Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

* "Add validation" → "Write tests for invalid inputs, then make them pass"
* "Fix the bug" → "Write a test that reproduces it, then make it pass"
* "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Verify Before You Declare Success

**"Looks right" is not verification. Execute checks.**

* Don’t claim something works without validating it.
* Prefer execution over reasoning:

  * Run the code if possible.
  * If not, walk through a concrete example step-by-step.
* For transformations:

  * Show input → output examples.
* For queries:

  * Validate edge cases (empty, nulls, duplicates).
* For refactors:

  * Confirm behavior is unchanged (not just structure).

If you cannot verify:

* Say explicitly: *"This is unverified because X"*.
* Suggest how to verify it.

---

## 6. Respect Existing State and Constraints

**The system already has rules. Don’t overwrite them.**

* Don’t redefine variables, configs, or assumptions unless required.
* Don’t introduce new patterns if the project already uses one.
* Don’t silently change data shapes, contracts, or interfaces.
* If something feels wrong:

  * Flag it.
  * Don’t fix it unless asked.

When adding logic:

* Ensure compatibility with existing inputs/outputs.
* Assume downstream dependencies exist—even if you don’t see them.

---

## 7. Don’t Hallucinate APIs, Data, or Behavior

**If you don’t know, don’t invent.**

* Don’t assume:

  * Library functions
  * API responses
  * Table schemas
* If something is unknown:

  * Ask
  * Or clearly mark assumptions

Bad:

* “This endpoint returns X”

Good:

* “Assuming this endpoint returns X (needs confirmation)”

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## 8. Working Files

Any output file or input file created during a session — analyses, CSVs, reports, scratch data, downloaded content — must be written to the `temp/` directory, never the repo root or any other location in the working directory.

`temp/` is gitignored and created automatically by `setup.sh`. If it does not exist, create it before writing any file.
