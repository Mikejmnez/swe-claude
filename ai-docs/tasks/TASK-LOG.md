<!-- CONTRACT: scoped engineering/maintenance work that isn't new capability (FR/NFR/
     UC) and isn't corrective (BUG) — dependency bumps, removing dead code or stale
     compile-time directives, retrofitting tests onto code that predates them,
     build/tooling changes. The common thread: the "right" outcome is usually
     mechanical and completeness matters (did every instance get handled?), not
     open-ended design. Delete the TASK-EXAMPLE section once you've seen the shape. -->

# Task Log

Convention: `TASK-###`, sequential, never renumbered. Status: `Open` → `Plan Ready` →
`In Progress` → `Done` (or `Won't Do` / `Superseded by TASK-0XX`). **Only the user sets
`Done`** — it's a claim about verified work, not something to self-report from having
written a plan. Category is one of: Dependency
Update, Code Cleanup, Test Coverage, Build/Tooling, Documentation (add categories as
needed).

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

## TASK-001 — Rename `docs/` and `plans/` to `ai-docs/` and `ai-plans/`

**Category:** Build/Tooling
**Status:** In Progress
**Created:** 2026-11-03
**Related requirements/constraints:** None found. The requirement, constraint and
decision docs hold only `_EXAMPLE_` entries.
**Plan:** `ai-plans/task-ai-dir-prefix-plan.md`

**Scope:** `git mv` this repo's `docs/` → `ai-docs/` and `plans/` → `ai-plans/`.
Rewrite every `docs/` and `plans/` path reference in `CLAUDE.md`, `CLAUDE-bes.md`,
`README.md`, every file under `.claude/`, and every file in the renamed directories.
Change `link-swe-claude.sh` to always link them as `ai-docs` / `ai-plans` (drop the
`docs`→`ai-docs` fallback and the closing "note:" message). Make the script migrate
projects linked by the old version: remove symlinks that point at `$SRC/docs` or
`$SRC/plans`, create the new links, and update `.git/info/exclude` to match.
Not included: `Claude-outputs/prompt-audit/` (a historical record, left as-is), the
`*-conventions.md` snippets (no references), and fixing links in projects that point
at a swe-claude checkout other than the one the script runs from.

**Motivation:** Most target projects already have their own `docs/` (and sometimes
`plans/`), so the `ai-` prefix should be the default. A single fixed name also lets
`CLAUDE.md` give correct paths in every project, and the fallback logic can go.

---

<!-- Add new tasks via /plan-task, or by hand — keep the section format: metadata
     lines, then Scope / Motivation. Unlike a bug, a task doesn't need a symptom or
     reproduction — it needs a clear boundary of what's included and what isn't,
     since "remove all the X" quietly becoming "remove most of the X" is the
     characteristic failure mode here. -->
