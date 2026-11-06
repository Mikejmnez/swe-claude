---
paths:
  - "**/*.ipynb"
---

# Notebook rules — Jupyter

Loaded when a notebook is read or edited. Project-level choices (where notebooks
live, which kernel, the run command) are in the project's `CLAUDE.md` Conventions
section, from `jupyter-conventions.md`.

- **Edit the paired `.py`, not the `.ipynb`.** Every notebook is paired by jupytext
  with a percent-format script (`# %%` cell markers). Make changes in the `.py`, then
  `jupytext --sync <file>` so the two agree. Never hand-edit the notebook's JSON. If a
  notebook has no pair, pair it first (`jupytext --set-formats ipynb,py:percent`) and
  say so.
- **Notebooks are committed without outputs.** `nbstripout` (installed as a git filter
  in the repo) strips them; don't commit outputs by any other route, and don't read a
  committed notebook's outputs as evidence of a result — there are none. Results come
  from running it.
- **A notebook presents; it does not hold reusable logic.** A function used by more
  than one notebook, or worth a test, moves into the project's package and is
  imported. Notebook cells call functions, set parameters, and show results.
- **Parameters at the top.** One cell near the top holds every input (data paths,
  dataset versions, thresholds, seeds), tagged `parameters`, so the notebook can be
  re-run with different inputs without editing logic cells.
- **"Done" means it runs top to bottom in a fresh kernel** — the project's run
  command, never "the cells I ran worked". Out-of-order execution and state left over
  from deleted cells are the usual cause of results nobody can reproduce.
- **No hardcoded absolute paths** (`/Users/...`); paths are relative to the repo root
  or come from the parameters cell.
- **Outputs that reach the manuscript are written, not screenshotted.** A figure is
  saved to the manuscript's figures folder by code; a number that appears in the text
  is written to the generated macros file (see `.claude/rules/latex.md`). Name the
  output files the notebook writes in a markdown cell at its top.
- **Never fabricate a result.** If a value needs a run that hasn't happened, say
  "unmeasured" and leave a `[[RESULT: …]]` placeholder rather than estimating.
