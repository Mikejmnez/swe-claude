# Task Plan: Branch rules when a project's records live in a separate repo

**Task:** TASK-002
**Status:** Done
**Created:** 2026-11-06
**Approved:** 2026-11-06 — option A.

## Summary

Decide how the "Branch & working-tree discipline" section of `planning-rules.md`
applies when `link-swe-claude.sh -r` keeps a project's `ai-docs/`, `ai-plans/` and
`CLAUDE.md` in a separate records repo; record the decision as an ADR in swe-claude's
own `ai-docs/decisions/DECISIONS.md`; and edit `planning-rules.md` (and the README's
option B section) to match.

## Motivation

The rule today says a plan, log entry or code change "must happen on its own branch,
never directly on `main`", after checking the working tree is clean. Under `-r` that
breaks in two ways:

- **The clean-tree check misses the records.** All six links are in the project's
  `.git/info/exclude`, so `git status` in the project shows nothing about
  `ai-docs/`, `ai-plans/` or `CLAUDE.md`. A dirty records folder passes the check.
- **"On that item's branch" has no single meaning.** A TASK-LOG entry is written into
  the records repo, not the project, so the project's branch does not contain it.

TASK-001's plan ("Open questions", "Branch discipline") says this should be settled
before any real project is set up with `-r`.

## Related requirements / constraints

None — swe-claude's own requirement and constraint docs hold only `_EXAMPLE_`
entries. Constraint from swe-claude's `CLAUDE.md`: **`planning-rules.md` holds no
placeholders and nothing project-specific** — every project imports it, `-r` or not,
so the new rule must say how to tell which case applies rather than assume one.

## Scope

**In scope:**
- The decision (which option below), as `ADR-001` in swe-claude's top-level
  `ai-docs/decisions/DECISIONS.md`.
- A subsection under "Branch & working-tree discipline" in `planning-rules.md`
  covering the `-r` case: how to detect it, what the clean-tree check covers, where
  branches are and are not made, and how record commits are labelled.
- The README's option B paragraph beginning "After working in a project, commit and
  push the records there", if the decision changes what it says.
- The commands (`/plan-task`, `/fix-bug`, `/plan-feature` and the rest): only where
  they restate the branch rule. I grepped `.claude/commands/` for `branch` and `git`
  on 2026-11-06; none restates it (the only hit is `/init-planning` asking for the
  project's "branching convention"), so as of now no command edit is expected.

**Out of scope:** the other two TASK-001 open questions (`settings.json` under `-r`;
moving a project's own `.claude/plans/` and `.claude/skills/` into the records
repo); any change to
`link-swe-claude.sh`; a records repo per project instead of one shared one; setting up
any real project; the default (non-`-r`) rule, which stays as written.

## Options

What the README sets up today: **one** records repo for all projects
(`~/Git_Repos/swe-records/<project>/`), cloned on two machines.

**A. Records repo has no feature branches (recommended).** Code follows the existing
rule unchanged: its own `mju/<slug>` branch in the project. Records are edited on the
records repo's `main` and committed there, with the project and item in the message
(e.g. `<project>: TASK-004 log and plan (branch mju/<slug>)`). The clean-tree check
runs in both repos; in the records repo it is scoped to the project's folder
(`git status --short -- <project>/`), so another project's uncommitted records do not
block this one.

- For: works with one shared records repo — switching branches there never changes
  another project's files on disk; nothing extra to merge; matches what the README
  already tells the user to do.
- Against: a record change and the code it describes are not in one branch or one
  merge, so "revert the branch" does not revert the plan. Records of abandoned work
  stay on `main` (they are history either way — IDs are never reused).

**B. Mirror branches.** The same `mju/<slug>` branch is made in the records repo, and
merged when the project's branch merges.

- For: a records change and its code have a matching name and lifecycle.
- Against: the records repo is shared, so checking out a branch there switches every
  project's records at once — working on two projects at the same time, or two items
  in one project, fights over one checkout. Doubles the branch bookkeeping, and
  "Always ask before creating or switching branches" becomes two asks per item.

**C. Records repo per project.** Would make B workable, but changes the layout TASK-001
built and the README documents; out of scope here, listed so its absence is visible.

## Approach

1. You choose A or B (ASK in the report). Steps below assume A; B changes step 3's
   text, not the steps.
2. Write `ADR-001` in `ai-docs/decisions/DECISIONS.md`: context (the two breaks above),
   decision, alternatives B and C with why not, consequences (no shared revert;
   clean check now spans two repos). `Status: Accepted` once you approve it.
3. Add to `planning-rules.md`, under "Branch & working-tree discipline", a subsection
   "When records live in a separate repo", saying:
   - **How to tell:** `ai-docs` in the project root is a symlink (`test -L ai-docs`);
     the records repo is `git -C "$(dirname "$(readlink ai-docs)")" rev-parse
     --show-toplevel`. If it is not a symlink, nothing in the subsection applies.
   - **Clean check:** run `git status` in the project *and* in the records repo,
     scoped to the project's folder; either dirty → stop and ask, as today.
   - **Branches:** code on its own branch in the project, as today; records on the
     records repo's `main`, never a branch there.
   - **Commits:** record commits name the project and the ID(s), and the project
     branch if there is one. Commit only when the user asks, as everywhere else.
4. Update the README option B paragraph only if step 3 adds anything it contradicts
   (e.g. the commit-message form).
5. Re-run the grep from "Scope" to confirm no command restates the branch rule; if one
   now does, add a one-line pointer to the new subsection rather than a second copy.

## Verification

- Read the edited "Branch & working-tree discipline" section in full and check every
  sentence still holds for a project **without** `-r` (no wording that assumes records
  are elsewhere).
- Grep record for completeness: `grep -rn -i -E 'branch|git status|working tree'
  planning-rules.md .claude/ README.md` before and after; every hit afterwards either
  agrees with the new subsection or is about something else.
- Manual, in scratch repos under the session scratchpad (never a real project): a
  scratch project installed with `-r` into a scratch records repo, with an uncommitted
  file in the records folder. Start `claude`, run `/plan-task` on a dummy task, and
  confirm Claude (a) finds the dirty records folder and stops to ask, and (b) after it
  is clean, proposes a branch in the project and none in the records repo. Repeat in a
  scratch project installed without `-r` and confirm behaviour is unchanged.

**Results (2026-11-06):**
- Wording and grep checks: done by Claude; the only `-r`-specific wording is the new
  subsection and the pointer to it; no command restates the branch rule; the four
  README hits agree.
- Manual check, run by Miguel in scratch repos (records repo with an uncommitted file
  in the project's folder and another in a second project's folder):
  (a) with `-r`, Claude stopped on the project's uncommitted records file and did not
  flag the other project's — pass; (b) once clean, it proposed a branch in the project
  and none in the records repo — pass; (c) without `-r`, it found a clean tree on
  `main`, noted `ai-docs` is a regular folder, and put the work on a branch in the
  project — pass. The scratch records repo had no remote, so the "behind its remote"
  check was not exercised.

## Risks

- **Two-repo check is easy to skip.** The rule depends on Claude noticing the symlink.
  If it doesn't, behaviour falls back to today's (records unchecked) — no worse than
  now, but silent. The manual check is the only test of this.
- **Machines drift.** With records on `main` on two machines, forgetting to pull before
  working gives a merge conflict in the records repo. The rule could say "pull the
  records repo first" — see open questions.
- **Shared-repo scoping.** `git status -- <project>/` only works if the records folder
  is named after the project as the README suggests; the rule should derive the folder
  from the link target, not from the project's name.

## Open questions

- **A or B?** Blocks step 2 onward. Recommendation: A.
- **Should the rule tell Claude to `git pull` the records repo before starting work?**
  Does not block: proposed default is no — pulling is a networked, state-changing
  action, so the rule would say "check the records repo is not behind its remote
  (`git status -sb`) and tell the user if it is" rather than pull.
