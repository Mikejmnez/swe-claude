<!-- This file is auto-loaded by Claude Code at the start of every session in this
     repo. It is a CONTRACT, not a log. Keep it short. It describes swe-claude
     itself; the rules every project gets are in planning-rules.md. -->

# CLAUDE.md — swe-claude

**What:** the requirements-driven planning kit for software projects — decisions (`ADR-###`), bugs (`BUG-###`) and tasks (`TASK-###`). Research projects use claude-config instead.
**Produces:** `planning-rules.md`, `.claude/` commands and rules, the `template/` copied into each project, and `link-swe-claude.sh`, which installs them.
**State:** see `ai-docs/tasks/TASK-LOG.md`.

## Layout

| Path | Holds | Reaches a project how |
|---|---|---|
| `planning-rules.md` | the planning rules (IDs, don't invent, branches, commands) | imported by an `@` line the link script appends to the project's `CLAUDE.md` |
| `.claude/` | commands, file-type rules, the requirements-reviewer agent | linked |
| `template/ai-docs/`, `template/ai-plans/` | blank logs with `_EXAMPLE_` entries, plan templates | copied once; the project's copy is its own |
| `template/CLAUDE.md` | skeleton project `CLAUDE.md` with `{{…}}` fields | copied only when the project has no `CLAUDE.md` |
| `*-conventions.md` | Conventions snippets (Python, Jupyter, LaTeX) | pasted by hand into the project's `CLAUDE.md` |
| `link-swe-claude.sh` | the installer | run by hand, on a new or existing repo |
| `ai-docs/`, `ai-plans/` | **swe-claude's own** records and plans | never — they are not the template |

`ai-plans/_template-*.md` here are links to `template/ai-plans/`, so this repo's own
commands find the same templates projects get.

## Conventions

- **A change meant for projects goes in `template/`, `planning-rules.md`, `.claude/`
  or a conventions snippet — never in the top-level `ai-docs/`.** Those are this
  repo's own records. Projects already linked keep their copies of `template/`;
  only `planning-rules.md` and `.claude/` reach them live.
- **`planning-rules.md` holds no placeholders and nothing project-specific** — every
  project imports it as-is.
- **`link-swe-claude.sh` is written for bash 3.2** (macOS). After changing it, run it
  against a scratch git repo, twice (it must be idempotent), and once with `-n`.
- Branch names are `mju/<slug>`; see `planning-rules.md`.

@planning-rules.md
