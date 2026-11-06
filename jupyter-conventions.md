<!-- Paste the body below into CLAUDE.md in place of the {{CONVENTIONS}} placeholder
     (alongside python-conventions.md, which governs the package code notebooks
     import), and drop or demote this H2 so CLAUDE.md keeps a single
     `## Conventions` heading. The per-file rules live in .claude/rules/notebooks.md. -->

## Conventions — Jupyter notebooks

**Where:** notebooks live in `{{NOTEBOOK DIR — e.g. notebooks/}}`, each paired by
jupytext with a percent-format `.py` beside it. Reusable code lives in the package
(`src/{{PACKAGE}}/`) and follows `python-conventions.md`; notebooks import it.

**Kernel:** the project's own virtual environment, registered as a named kernel
(`{{KERNEL NAME}}`), never the system or base Python. Jupyter, jupytext and
nbstripout are development dependencies of the project, so they are in the lock file.

**Setup, once per clone:**
- `nbstripout --install` — git filter that strips outputs on commit.
- `jupytext` pairing set project-wide in `pyproject.toml`
  (`[tool.jupytext] formats = "ipynb,py:percent"`), so every new notebook is paired.

**Run command:** `{{RUN COMMAND — e.g. uv run jupyter nbconvert --to notebook --execute --inplace notebooks/<name>.ipynb}}`
runs one notebook top to bottom in a fresh kernel. `{{RUN ALL — e.g. a make target or
script}}` re-runs every notebook that produces a manuscript figure or number, in
dependency order. A notebook is done only when its run command succeeds.

**Outputs:** notebooks are committed **without outputs**. Figures go to
`{{FIGURE DIR — e.g. LATEX/figures/}}`; numbers that appear in the manuscript go to
`{{MACROS FILE — e.g. LATEX/generated/results.tex}}`, written by code as
`\newcommand{\name}{value}`. Large intermediate data goes to
`{{DATA DIR — e.g. data/derived/, git-ignored}}`, never into git.

**Naming:** a notebook that produces a manuscript figure is named for it
(`fig03_orbit_position.ipynb`), so the `% source:` comment in the `.tex` file and the
notebook name agree.

**Records:** an analysis worth tracking is a `TASK-###` (category Analysis) planned
with `ai-plans/_template-analysis.md`. An analysis choice that constrains later work —
a threshold, a season definition, a dataset version — is an `ADR-###`, including
negative results ("tried X, does not work, here is the measurement").
