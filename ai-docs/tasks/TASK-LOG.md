<!-- CONTRACT: any tracked work that isn't new capability (FR/NFR/UC) and isn't
     corrective (BUG) — dependency bumps, removing dead code or stale compile-time
     directives, retrofitting tests onto code that predates them, build/tooling
     changes, an analysis or figure, a documentation pass. The test for logging one
     at all: does it need a status line — can it meaningfully be in progress or
     blocked? A question, a lookup or a one-line fix is not a task. Whatever the kind,
     pin the scope down: completeness (did every instance get handled?) is where tasks
     fail quietly. Delete the TASK-EXAMPLE section once you've seen the shape. -->

# Task Log

Convention: `TASK-###`, sequential, never renumbered. Status: `Open` → `Plan Ready` →
`In Progress` → `Done` (or `Won't Do` / `Superseded by TASK-0XX`). **Only the user sets
`Done`** — it's a claim about verified work, not something to self-report from having
written a plan. Category is one of: Dependency
Update, Code Cleanup, Test Coverage, Build/Tooling, Documentation, Analysis (add
categories as needed). An Analysis task is planned with `ai-plans/_template-analysis.md`.

---

## TASK-EXAMPLE — Add unit tests for the legacy `parser/` module

*(delete this section once you've seen the shape)*

**Category:** Test Coverage
**Status:** Plan Ready
**Created:** YYYY-MM-DD
**Related requirements/constraints:** None found — `parser/` predates FR/NFR/UC
tracking in this repo
**Plan:** `ai-plans/task-parser-test-coverage-plan.md`

**Scope:** Every public function in `parser/`, tested against the fixtures already
in `parser/testdata/`. Does not include refactoring the module itself, even where
the tests reveal awkward internal structure — that's a separate task if pursued.

**Motivation:** `parser/` has zero test coverage and has caused two regressions in
the last quarter that tests would have caught before merge.

---

## TASK-001 — Installer option to keep a project's records in a separate repo

**Category:** Build/Tooling
**Status:** Plan Ready
**Created:** 2026-11-06
**Related requirements/constraints:** None found — swe-claude's own requirement and
constraint docs hold only `_EXAMPLE_` entries
**Plan:** `ai-plans/task-installer-records-mode-plan.md`
**Paused:** 2026-11-06 — plan not yet approved; the user is first cleaning up the
four project directories. Resume with `/plan-task TASK-001`.

**Scope:** A `-r DIR` option to `link-swe-claude.sh` that keeps the project's
`ai-docs/`, `ai-plans/` and `CLAUDE.md` in `DIR` (one folder of a private records
repo) and symlinks them into the project; links swe-claude's `.claude/` subfolders
into the project's own `.claude/` rather than replacing it; and keeps every link out
of the project's git without a later run undoing that. Includes the script's header
and usage text, `README.md` and the `CLAUDE.md` layout table. Does not include
creating the records repo, setting up any real project, or changing how the script
behaves without `-r` beyond protecting exclude entries for symlinks.

**Motivation:** pydap and oceanspy are public upstream repos, and the records of all
four current projects (oceanspy, StirMix.jl, HillFunctions.jl, pydap) are to stay off
GitHub while syncing between two machines. Every one of those projects already has
its own `.claude/`, which the current installer refuses to touch, so none would get
the commands; and doing the layout by hand is six links plus their exclude lines,
per project, per machine — eight times over for four projects on two machines.

---

<!-- Add new tasks via /plan-task, or by hand — keep the section format: metadata
     lines, then Scope / Motivation. Unlike a bug, a task doesn't need a symptom or
     reproduction — it needs a clear boundary of what's included and what isn't,
     since "remove all the X" quietly becoming "remove most of the X" is the
     characteristic failure mode here. -->
