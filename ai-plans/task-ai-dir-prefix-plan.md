# Task Plan: Rename `docs/` and `plans/` to `ai-docs/` and `ai-plans/`

**Task:** TASK-001
**Status:** In Progress
**Created:** 2026-11-03

## Summary

Rename swe-claude's `docs/` and `plans/` directories to `ai-docs/` and `ai-plans/`.
Update every path reference in the Markdown scaffolding to match, and change
`link-swe-claude.sh` to always link the new names and migrate projects linked by
the old version.

## Motivation

Most projects that swe-claude gets linked into already have a `docs/`, and some have
a `plans/`. Today the script falls back to `ai-docs` / `ai-plans` in that case, so
`CLAUDE.md` names the wrong paths in exactly the projects where the fallback fired,
and the script ends with a "note: CLAUDE.md refers to docs/..." warning. Making
`ai-` the only name removes the collision, keeps the paths in `CLAUDE.md` correct
everywhere, and deletes the fallback code.

## Related requirements / constraints

None. `ai-docs/requirements/`, `ai-docs/constraints/` and `ai-docs/decisions/` hold only
`_EXAMPLE_` entries.

## Scope

**In scope:**

- `git mv docs ai-docs` and `git mv plans ai-plans` in this repo, including this plan
  file and `TASK-LOG.md`.
- Path references (`docs/…`, `plans/…`, `` `docs/` ``, `` `plans/` ``) in these 20
  files (baseline below):
  - `CLAUDE.md`, `CLAUDE-bes.md`, `README.md`
  - `.claude/agents/requirements-reviewer.md`
  - `.claude/commands/{audit-plan,deep-dive,fix-bug,init-planning,new-requirement,plan-feature,plan-task,trace}.md`
  - `ai-docs/bugs/BUG-LOG.md`, `ai-docs/decisions/DECISIONS.md`,
    `ai-docs/deep-dives/README.md`, `ai-docs/requirements/functional-requirements.md`,
    `ai-docs/tasks/TASK-LOG.md`
  - `ai-plans/_template-bugfix.md`, `ai-plans/_template-plan.md`, `ai-plans/_template-task.md`
- `link-swe-claude.sh`: the header comment, the link loop, the migration of old
  links, the `.git/info/exclude` cleanup, and removal of the `renamed` note.

**Out of scope:**

- `Claude-outputs/prompt-audit/` (`REPORT.md`, `proposed-edits.patch`). These are a
  record of a past audit. Their paths will be stale after the rename, and that's
  intended.
- The word "docs" or "plans" used as prose rather than a path (e.g. "the requirement
  docs", "plans work from written requirements"), and URLs such as
  `docs.claude.com`.
- `.claude/rules/`, `.claude/settings.json` and the `*-conventions.md` files. The
  baseline grep found no path references in them; re-check and stop if that changes.
- Links in a target project that point at some other swe-claude checkout (another
  `$SRC`). The migration only recognizes links into the checkout the script runs from.
- Plans or log entries inside target projects. Those live in swe-claude itself
  through the symlink, so they move with the rename.

## Approach

1. **Baseline.** Record the count, using the pattern from the "Completeness check"
   section below. At plan time it was **90 lines across 20 files**.
2. **Rename the directories:** `git mv docs ai-docs` and `git mv plans ai-plans`.
   Commit this step on its own so the history follows the files.
3. **Rewrite path references** in the in-scope files: `docs/` → `ai-docs/`,
   `plans/` → `ai-plans/`, but only where the match is preceded by start-of-line or a
   character that isn't `[A-Za-z0-9_.-]`, so `ai-docs/` isn't rewritten twice and
   `docs.claude.com` isn't touched. Use a script for the mechanical part, then read
   each diff hunk to catch prose that shouldn't have changed.
   - Then review hits for the bare words `` `docs` `` / `` `plans` `` (no slash), e.g.
     a sentence naming the directory without a trailing slash. Decide each one by hand.
   - `README.md`: update the "What you get" tree, the Option B copy instructions
     (`ai-docs/`, `ai-plans/`), and "First steps" item 2.
   - `CLAUDE.md` / `CLAUDE-bes.md`: the intro paragraph, the "Read before planning"
     table, and the `_template-bugfix.md` / `_template-task.md` references.
4. **`link-swe-claude.sh`:**
   - Header comment: links `.claude`, `ai-docs`, `ai-plans` and `CLAUDE.md`; drop the
     "link it as ai-docs / ai-plans instead" line; describe the migration.
   - Before linking, for each `old` in `docs plans` and each `dest` in `old` and
     `ai-old`: if `is_our_link "$TARGET/$dest" "$old"` (a symlink to `$SRC/docs` or
     `$SRC/plans`), report `remove: $dest (old link to $SRC/$old)` and `run rm` it.
     If `dest` was the bare `docs` / `plans`, add it to a `stale_excludes` list.
     (`is_our_link` compares `readlink` strings, so it still matches after the
     source directory is gone.)
   - Replace the fallback loop with `make_link ai-docs ai-docs` and
     `make_link ai-plans ai-plans`. An existing non-link `ai-docs` / `ai-plans` in the
     target makes `make_link` warn and set status 1, as it already does.
     In a dry run, a link removed in the step above still exists, so make dry-run
     output say `link:` for those rather than `already exists`. This is the same
     problem the `CLAUDE.md` relink branch already handles.
   - In the `.git/info/exclude` block, remove lines matching `/$prefix$name` for each
     name in `stale_excludes`. Keep this bash 3.2 compatible: `grep -vxF` into a
     temp file next to `$ex`, then `mv`. Skip it in a dry run and say what would be
     removed. Only remove exact lines the old script would have written.
   - Delete the `renamed` variable and the closing `note:` loop.
5. **Re-run the completeness grep** (see below) and confirm the remaining hits are
   only in `Claude-outputs/`, or are `ai-docs/` / `ai-plans/`.

### Completeness check

```sh
# Old-style references outside the historical audit output. Target: 0.
grep -rnE '(^|[^A-Za-z0-9_.-])(docs|plans)/' --exclude-dir=.git --exclude-dir=Claude-outputs . \
  | grep -v 'docs\.claude\.com' | wc -l      # before: 90   after: 0

# New-style references. Should be about 90 (a few lines may hold two references).
grep -rnE 'ai-(docs|plans)/' --exclude-dir=.git --exclude-dir=Claude-outputs . | wc -l

# Bare-word directory mentions to review by hand:
grep -rnE '`(docs|plans)`' --exclude-dir=.git --exclude-dir=Claude-outputs .
```

Check off each of the 20 files listed under Scope as its diff is reviewed.

## Verification

- `bash -n link-swe-claude.sh`. Run `shellcheck` too if it's installed (it isn't on
  this machine at plan time).
- Scenario tests in throwaway git repos under the scratchpad. Run each scenario with
  `-n` first, then for real, then a second time to confirm the re-run is a no-op
  (`ok:` lines, exit 0, no duplicate lines in `.git/info/exclude`):
  1. Fresh project with no `docs/`: gets `ai-docs`, `ai-plans`, `.claude`, `CLAUDE.md`
     links, and all four are in `.git/info/exclude`.
  2. Fresh project with its own `docs/` and `plans/`: those are untouched, `ai-*`
     links are created, and no "note:" message is printed.
  3. Project linked by the old script, case A: `docs -> $SRC/docs`,
     `plans -> $SRC/plans`, exclude holds `/docs`, `/plans`. The old links are
     removed, `ai-*` links are created, and `/docs` / `/plans` are replaced by
     `/ai-docs` / `/ai-plans` in the exclude file.
  4. Project linked by the old script, case B (it had its own `docs/`):
     `ai-docs -> $SRC/docs`. The link is re-pointed to `$SRC/ai-docs`, the
     project's real `docs/` is untouched, and the exclude file is unchanged.
  5. Target is a subdirectory of a git repo: exclude patterns carry the prefix, and
     stale prefixed patterns are removed.
  6. Target has a real (non-link) `ai-docs/` directory: it's reported and left
     alone, and the exit status is 1.
  To create the old-style links, use `ln -s "$SRC/docs" docs` and so on. Dangling
  links are fine because the old source directories are gone.
- Open a fresh Claude Code session in this repo and in a linked project, run
  `/trace TASK-001`, and confirm it searches `ai-docs/` and `ai-plans/` and finds this
  entry.
- Read the full `git diff main` for every touched file.

## Risks

- **Over-matching in the rewrite**: prose like "requirement docs/plans" or a URL
  gets changed. The boundary regex plus a per-hunk diff read covers this.
- **Exclude cleanup deletes a user's own line**: a project could have written
  `/docs` into `info/exclude` by hand. The cleanup only removes lines for links the
  script itself just removed, which makes this unlikely but not impossible. Mention
  it in the script's output (`git: remove /docs from …`) so it's visible.
- **Other checkouts and copies**: projects set up with README "Option B" (copied, not
  linked) still have `docs/` and `plans/` with the old `CLAUDE.md`, and nothing
  migrates them. They keep working with their own copy.
- **Sessions already open** in linked projects have the old `CLAUDE.md` in context
  and will look in `docs/` until they're restarted.

## Open questions

- None. (Resolved 2026-11-03: the README gets no "upgrading from the old layout"
  note.)
