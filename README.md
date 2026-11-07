# swe-claude

NB: the top-level `ai-docs/` and `ai-plans/` are swe-claude's **own** records. What
projects receive is `template/`, `planning-rules.md` and `.claude/`; see `CLAUDE.md`.

A Claude Code project template for **requirements-driven planning**: write your
functional requirements, non-functional requirements, use cases, and implementation
constraints as plain markdown with stable IDs, and have Claude produce implementation
plans that cite those IDs — instead of planning from a conversation's worth of
half-remembered context.

This is a sibling idea to session-continuity templates like
[claude-config-public](https://github.com/OPENDAP/claude-config-public), which solves
a different problem (picking a research project back up after a month away). This
template solves: *"before Claude plans a feature, has it actually read what we agreed
the system should do, and will the plan say which requirement each step satisfies?"*

## What you get

```
planning-rules.md                           # rules every project imports into its CLAUDE.md
link-swe-claude.sh                          # installs the kit into a project
python-conventions.md                       # Conventions snippets, pasted by hand
jupyter-conventions.md
latex-conventions.md
template/                                   # copied into each project, once
  CLAUDE.md                                 # skeleton, only if the project has none
  ai-docs/
    requirements/
      functional-requirements.md            # FR-001, FR-002, ...
      non-functional-requirements.md        # NFR-001, ...
      use-cases.md                          # UC-001, ...
    constraints/
      implementation-constraints.md         # IC-001, ... — hard boundaries
    decisions/
      DECISIONS.md                          # ADR-001, ... — why, not what
    bugs/
      BUG-LOG.md                            # BUG-001, ... — report → root cause → fix
    tasks/
      TASK-LOG.md                           # TASK-001, ... — other tracked work (not a feature or bug)
    deep-dives/
      README.md                             # convention note; one file per investigation
  ai-plans/
    _template-plan.md                       # shape every generated feature plan follows
    _template-bugfix.md                     # shape every generated bugfix plan follows
    _template-task.md                       # shape every generated task plan follows
    _template-analysis.md                   # shape for Analysis tasks (data → figures/numbers)
.claude/                                    # linked into each project
  commands/
    init-planning.md      # /init-planning   — first-time interview & doc seeding
    plan-feature.md        # /plan-feature    — requirements → phased plan
    fix-bug.md              # /fix-bug         — log a bug, find root cause, plan the fix
    deep-dive.md             # /deep-dive       — read-only code investigation, saved findings
    new-requirement.md     # /new-requirement — add an FR/NFR/UC/IC by interview
    plan-task.md             # /plan-task       — log a task, draft a plan
    trace.md                # /trace           — find every reference to an ID
    audit-plan.md           # /audit-plan      — check a plan's citations, report only
  rules/
    notebooks.md           # loads for *.ipynb — pair with .py, no outputs, run top to bottom
    latex.md               # loads for *.tex/*.bib — generated numbers, figure sources, build
  agents/
    requirements-reviewer.md  # subagent that reviews docs for vague/untestable language
  settings.json            # example permission scaffold — verify against current docs
ai-docs/, ai-plans/                         # swe-claude's own records — not the template
```

Every requirement, use case, and constraint gets a stable ID (`FR-001`, `NFR-014`,
`UC-003`, `IC-002`). Plans in `ai-plans/` cite those IDs on every phase. `/trace` and
`/audit-plan` exist so that "does anything actually cover this?" and "did this plan
wander off scope?" are one command away instead of a manual grep.

**Bugs get a parallel ID space, `BUG-###`, deliberately not folded into the FR/NFR/UC
shape.** A bug isn't new capability satisfying a requirement — it's existing behavior
deviating from one (or from something that was never written down in the first
place). `/fix-bug` logs it, investigates root cause read-only, and drafts a bugfix
plan with regression risk and verification steps instead of delivery phases.

**Tasks get a third parallel ID space, `TASK-###`.** Not new capability like an FR,
not a correction like a bug — scoped engineering work such as dependency bumps,
removing dead compile-time directives, or retrofitting tests onto code that predates
them. `/plan-task` logs it and drafts a plan that emphasizes scope (exactly what's
in, what's explicitly out) and how completeness gets checked, since this kind of
task tends to fail quietly — a few instances missed — rather than loudly like a
broken build.

**`/deep-dive` is a standalone, read-only investigation command** for understanding
existing code — onboarding to an unfamiliar module, answering "how does X work,"
or checking whether the code still matches what the requirement docs claim. Findings
get saved to `ai-docs/deep-dives/` so the same investigation doesn't happen twice.
`/plan-feature` and `/fix-bug` both hand off to it when what they need is more than a
quick read-only look.

## Installing into a project

There are two ways to install, and they differ only in where the project's records
(`ai-docs/`, `ai-plans/`, `CLAUDE.md`) live:

| Option | Records live | Use it when |
|---|---|---|
| A. Records in the project | in the project, committed with its code | the project is yours and its records may be public with it |
| B. Records kept private (`-r`) | in a separate private records repo, linked into the project | the project is a public upstream repo, or the records should not travel with the code |

Either way, swe-claude's commands, agent and rules come in through links, and are
kept out of the project's `git status`. In the commands below, replace `<project>`
with the project's directory name and `<project-dir>` with its path, e.g.
`myproject` and `~/myproject`. The script is safe to re-run; always try `-n` (dry
run, changes nothing) first.

### Option A — records in the project

**Install.**

    ~/Git_Repos/swe-claude/link-swe-claude.sh -n <project-dir>    # dry run
    ~/Git_Repos/swe-claude/link-swe-claude.sh <project-dir>

What it does:

- links `<project-dir>/.claude` to swe-claude's `.claude/`, and adds `/.claude` to
  the project's `.git/info/exclude`. **If the project already has its own `.claude/`,
  this step is refused** (reported, exit status 1) — use option B, which links into
  an existing `.claude/` instead.
- copies `template/ai-docs` and `template/ai-plans` into the project, unless it
  already has them. They are the project's own copy, with its own ID sequences, and
  are meant to be committed.
- appends an `@~/Git_Repos/swe-claude/planning-rules.md` line (under a
  `<!-- swe-claude planning rules … -->` comment) to the project's `CLAUDE.md`; a
  project with none first gets `template/CLAUDE.md`, whose `{{…}}` fields need
  filling in.

Then commit `ai-docs/`, `ai-plans/` and `CLAUDE.md` in the project.

**Remove.** From the project's top directory:

    rm .claude                                         # the link only
    grep -vxF '/.claude' .git/info/exclude > .git/info/exclude.new && mv .git/info/exclude.new .git/info/exclude
    grep -vxF -e '@~/Git_Repos/swe-claude/planning-rules.md' \
        -e '<!-- swe-claude planning rules, added by link-swe-claude.sh -->' CLAUDE.md > CLAUDE.md.new && mv CLAUDE.md.new CLAUDE.md

`ai-docs/`, `ai-plans/` and `CLAUDE.md` are the project's own files: delete them
(`git rm -r`) only if you no longer want the records.

### Option B — records kept private (`-r`)

**Install.** One folder per project inside a private records repo, here
`~/Git_Repos/swe-records`:

    ~/Git_Repos/swe-claude/link-swe-claude.sh -n -r ~/Git_Repos/swe-records/<project> <project-dir>    # dry run
    ~/Git_Repos/swe-claude/link-swe-claude.sh -r ~/Git_Repos/swe-records/<project> <project-dir>

What it does:

- creates `~/Git_Repos/swe-records/<project>/` if missing, and seeds it from
  `template/` with `ai-docs/`, `ai-plans/` and `CLAUDE.md` (plus the import line).
  Anything already there is never overwritten.
- links `<project-dir>/ai-docs`, `ai-plans` and `CLAUDE.md` to that folder, so every
  edit made in the project lands in the records repo.
- keeps the project's `.claude/` a real directory (creating it if missing) and links
  swe-claude's `commands/`, `agents/` and `rules/` into it. Anything else in it —
  `plans/`, `skills/`, `settings.json` — is left alone; `settings.json` is never
  linked.
- adds all six links to the project's `.git/info/exclude`, so nothing shows in its
  `git status` or reaches its remote.

Anything already in the project under one of those six names, and not the expected
link, is reported and left alone (exit status 1); move it out of the way and re-run.

The script never runs git in the records folder. The first time, make it a repo and
keep it private:

    cd ~/Git_Repos/swe-records && git init     # once; then add a private remote

After working in a project, commit and push the records there, not in the project:

    cd ~/Git_Repos/swe-records && git add -A && git commit -m "<project>: …" && git push

**Second machine.** Clone swe-claude and swe-records to the **same paths** as on the
first machine (the links are absolute), then run the same install command. The
folder is already seeded, so it only makes the links and exclude lines.

**Remove.** From the project's top directory:

    rm ai-docs ai-plans CLAUDE.md .claude/commands .claude/agents .claude/rules    # links only
    rmdir .claude          # fails, harmlessly, if the project has its own files in .claude/
    grep -vxE '/(ai-docs|ai-plans|CLAUDE\.md|\.claude/(commands|agents|rules))' .git/info/exclude \
        > .git/info/exclude.new && mv .git/info/exclude.new .git/info/exclude

The records stay in `~/Git_Repos/swe-records/<project>/`; delete that folder too only
if you no longer want them.

### Checking that it works (either option)

In the project's top directory:

    git status --short     # nothing from swe-claude should appear
    ls -la . .claude       # the links, and where they point

Then start Claude Code there (`claude`) and check three things:

1. Type `/` — `/plan-task`, `/plan-feature` and the other commands are listed. (The
   commands come through a link.)
2. Ask *"what planning rules apply here?"* — the answer describes the `FR`/`TASK`
   IDs and the branch rules. (`CLAUDE.md` and its import line were read.)
3. Ask it to append a line `test` to `ai-docs/tasks/TASK-LOG.md`, then check where the
   line landed and remove it. With option B it must be in the records repo:

       tail -1 ~/Git_Repos/swe-records/<project>/ai-docs/tasks/TASK-LOG.md

### After installing

The conventions snippets (`*-conventions.md`) are optional: paste the ones a project
uses into the Conventions section of its `CLAUDE.md`. Run `/init-planning` to seed the
requirement docs from the existing codebase and an interview, rather than starting
from blank tables.

## First steps in a new project

1. Fill in the project's own `CLAUDE.md` (description and Conventions) — or run
   `/init-planning` and let the interview do it.
2. Delete the `_EXAMPLE_` rows in each `ai-docs/requirements/*.md` and
   `ai-docs/constraints/*.md` file once you've seen the format — they're there to show
   the table shape, not to be real requirements.
3. Run `/new-requirement` a few times to populate real FRs/NFRs/UCs/ICs, or `/init-
   planning` to do it as one interview.
4. Run `/plan-feature <something>` and check that the plan it writes to `ai-plans/`
   actually cites the IDs you just wrote.

## Design choices worth knowing about

- **IDs are never renumbered or reused.** A dropped requirement is marked
  `Superseded` or `Deprecated`, not deleted — otherwise a plan written last month
  cites an ID that silently means something else now.
- **Claude is instructed not to invent requirements.** If you ask for a feature with
  no backing FR/UC, `/plan-feature` will say so and offer `/new-requirement` rather
  than writing a plausible-sounding one and treating it as fact.
- **`/trace` and `/audit-plan` only report — they never edit.** Traceability checks
  that silently "fix" things by rewriting docs are how requirements quietly drift
  from what was actually agreed.
- **`.claude/settings.json` is an illustrative starting point**, not a verified
  current schema — Claude Code's settings format can change; check
  https://docs.claude.com/en/docs/claude-code/overview before relying on it.

## License

MIT — use it, change it, ship it.
