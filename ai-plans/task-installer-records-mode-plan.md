# Task Plan: Installer option to keep a project's records in a separate repo

**Task:** TASK-001
**Status:** Done
**Created:** 2026-11-06
**Resumed:** 2026-11-06 — project clean-up reported done; see *Current state of the
four projects*. Approved 2026-11-06.

## Summary

Add `-r DIR` to `link-swe-claude.sh`. With it, the project's `ai-docs/`, `ai-plans/`
and `CLAUDE.md` live in `DIR` — one project's folder inside a private records repo
such as `~/Git_Repos/swe-records/<project>/` — and are symlinked into the project;
swe-claude's `.claude/` subfolders are linked into the project's own `.claude/`; and
all of it stays out of the project's git, durably.

## Motivation

The records of pydap and oceanspy must not reach their public upstream repos, and the
user wants the same for StirMix.jl and HillFunctions.jl, with all four syncing
between two machines through one private records repo. Today's installer cannot do
this: it copies `ai-docs/` and `ai-plans/` into the project (so they are either
committed or unsynced), and it refuses to link `.claude/` into a project that has its
own — which HillFunctions.jl and StirMix.jl do, holding `plans/` and `skills/` the
user wants kept. The by-hand alternative is six links plus exclude lines per project
per machine.

## Current state of the four projects

Checked on 2026-11-06 with `ls`, `git ls-files` and `git check-ignore` in each repo:

| Project | Path | `.claude/` | `CLAUDE.md`, `ai-docs/`, `ai-plans/` |
|---|---|---|---|
| oceanspy | `~/oceanspy` | none | none |
| pydap | `~/pydap` | none | none |
| HillFunctions.jl | `~/HillFunctions.jl` | `plans/` (2 files), `skills/` (1 file); untracked, ignored by the tracked `.gitignore` line `.claude/*` | none |
| StirMix.jl | `~/StirMix.jl` | `plans/` (7 files), `skills/` (1 file); untracked, ignored by the tracked `.gitignore` line `.claude/*` | none |

So oceanspy and pydap take the "no `.claude/`" branch of scope item 3, and the two
Julia projects take the "own `.claude/`" branch, with no name clash: neither has
`commands/`, `agents/` or `rules/`. None of the four has an `.git/info/exclude`
entry today.

## Related requirements / constraints

None. swe-claude's own requirement and constraint docs hold only `_EXAMPLE_` entries.
The conventions in swe-claude's `CLAUDE.md` apply: bash 3.2, idempotent, tested with
`-n`.

## Scope

**In scope** — `link-swe-claude.sh`, `README.md`, `CLAUDE.md` (this repo's), and
nothing else:

1. **`-r DIR` option.** `DIR` is created if missing. For each of `ai-docs`,
   `ai-plans`: if `DIR/<name>` is missing, copy it from `template/`. If `DIR/CLAUDE.md`
   is missing, copy `template/CLAUDE.md` and append the planning-rules import line;
   if present, append the import line only when absent. Then link
   `TARGET/<name> -> DIR/<name>` for all three.
2. **Existing target files under `-r`.** A real (non-link) `ai-docs`, `ai-plans` or
   `CLAUDE.md` in the target is reported and left alone, status 1 — never moved or
   overwritten. A link already pointing at `DIR/<name>` is `ok`.
3. **`.claude/` under `-r`.** If the target has no `.claude/`, create a real
   directory. Inside it, link `commands`, `agents` and `rules` to swe-claude's; any of
   those three that already exists and is not our link is reported and left alone,
   status 1. Everything else in the project's `.claude/` (e.g. the Julia projects'
   `plans/` and `skills/`) is untouched: not moved, not linked, not excluded. `settings.json` is not linked (see Open questions).
4. **Excludes.** Under `-r`, add `/ai-docs`, `/ai-plans`, `/CLAUDE.md`,
   `/.claude/commands`, `/.claude/agents`, `/.claude/rules` (skipping tracked paths,
   as now). Not the whole `/.claude`: that would also hide new files the project may
   want to commit there.
5. **Stale-exclude cleanup must not undo (4).** In both modes, an entry in the
   stale-exclude list is removed only if the path it names is not currently a
   symlink. This also protects projects set up by hand before this task.
6. **Argument checks.** `DIR` must not be the target, inside the target, or inside
   swe-claude. `-r` with `-n` reports and changes nothing — including not creating
   `DIR`.
7. **Docs.** Script header comment and `usage()`; `README.md` install section (both
   modes, and the second-machine flow: clone the records repo, run the same command);
   the `link-swe-claude.sh` row in this repo's `CLAUDE.md` layout table.

**Out of scope:**

- Creating `swe-records`, `git init`, GitHub, or any commit or push in `DIR`. The
  script never runs git in `DIR`.
- Setting up oceanspy, StirMix.jl, HillFunctions.jl or pydap — a follow-on, after
  this lands.
- Per-subfolder `.claude/` linking **without** `-r` (would fix pydap-style conflicts
  for projects that do commit their records). Possible later task.
- Projects that track their own `CLAUDE.md`: under `-r` they hit case (2) and get a
  warning. No `CLAUDE.local.md` route this time.
- Moving existing real `ai-docs/` / `ai-plans/` into `DIR` (migration).
- Moving or syncing a project's own `.claude/plans/` or `.claude/skills/` through
  `DIR`. They stay in the project, on one machine (see Open questions).
- Adding `@AGENTS.md` for pydap — a hand edit to `swe-records/pydap/CLAUDE.md`.
- A Julia conventions snippet.
- The branch-discipline wording in `planning-rules.md` (see Open questions).

## Approach

1. Read the whole script again; note every place that assumes `.claude` is one link,
   or that `ai-docs`/`ai-plans` are copies.
2. Add `-r` to `getopts`, the argument checks (6), and an absolute, resolved `DIR`.
3. Branch the `.claude` step: unchanged without `-r`; per-subfolder (3) with it.
4. Branch the `ai-docs`/`ai-plans` step: unchanged without `-r`; seed-then-link (1, 2)
   with it.
5. Branch the `CLAUDE.md` step the same way; reuse the existing import-line code for
   the file in `DIR`.
6. Change stale-exclude removal per (5); feed the `-r` names into `excludes` per (4).
7. Update the docs (7).

Completeness check: the six names in (4) are the full list of links `-r` creates;
each test below asserts all six links and all six exclude lines by name, not by eye.

## Verification

Scratch repos under the session scratchpad, never a real project. For each case:
run with `-n` (assert nothing changed, `DIR` not created), run once, run again
(assert all `ok`, exit 0, import line appears exactly once in `DIR/CLAUDE.md`, no
duplicate exclude lines), and check `git status --short` shows none of the six.

| Case | Setup | Expect |
|---|---|---|
| Fresh | empty git repo, `DIR` absent | `DIR` seeded; six links; six excludes |
| Own `.claude/` | repo with `.claude/plans/x.md`, `.claude/skills/y.md`, and a committed `.gitignore` holding `.claude/*` (the Julia layout) | both files untouched; three links inside; `git status` clean |
| Second machine | `DIR` already seeded; fresh repo | nothing copied into `DIR`; six links |
| Conflict | repo with real `ai-docs/` | warned, left alone, exit 1; others still linked |
| Re-run without `-r` | after Fresh | exclude lines still present |
| Bad `DIR` | `DIR` = target, inside target, inside swe-claude | refused, exit 1, nothing changed |
| Old mode | plain repo, no `-r` | output identical to before this task |

Then once by hand: start `claude` in the Fresh scratch repo and confirm `/plan-task`
is listed and can read `ai-docs/tasks/TASK-LOG.md` through the link. This is the only
check that Claude Code follows symlinked command folders and edits through linked
`ai-docs/`.

**Manual check done (2026-11-06):** run by Miguel; `-r` works as expected — commands
listed and linked `ai-docs/` readable through the link.

## Risks

- **Claude Code and symlinks** (checked by hand 2026-11-06, worked): command folders linked one level inside
  `.claude/`, and edits to `ai-docs/` whose real path is outside the project, may
  behave differently from the whole-`.claude` link, e.g. permission prompts for
  `Edit(./**)`. The manual check above catches it.
- **Records go uncommitted.** Changes in `DIR` do not show in the project's
  `git status`; nothing in this task prompts to commit them.
- **Paths per machine.** The four projects are at `~/<name>`, not under
  `~/Git_Repos`; links are absolute; both machines need the records repo and
  swe-claude at the same `~`-relative paths. The script cannot enforce this.
- **Regression in the default mode** — covered by the "Old mode" case.

## Open questions

- **The Julia projects' `.claude/plans/` and `.claude/skills/`:** they are not in any
  repo today (ignored by `.claude/*`), so they exist on one machine only. This plan
  leaves them there. Moving them into `DIR` would sync them, but is a migration and is
  out of scope.

- **`settings.json`:** swe-claude's only allows `Read(./**)` and `Edit(./**)`. Under
  `-r`, link it when the project has none, or never? Does not block: proposed default
  is never, since a project's own settings are its business.
- **Branch discipline:** `planning-rules.md` says record changes go on the item's
  branch with the code; under `-r` they are in another repo. Whether and how
  `planning-rules.md` should say so is out of scope here, but should be decided before
  the four projects are set up.
