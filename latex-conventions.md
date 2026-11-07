<!-- Paste the body below into the project's own CLAUDE.md, in its Conventions
     section, and drop or demote this H2 so CLAUDE.md keeps a single `## Conventions` heading.
     The per-file rules live in .claude/rules/latex.md. -->

## Conventions — LaTeX manuscript

**Where:** `{{LATEX DIR — e.g. LATEX/}}`, with `{{MAIN FILE — e.g. main.tex}}` as the
single root, one file per section under `{{SECTIONS DIR — e.g. LATEX/sections/}}`,
figures in `{{FIGURE DIR — e.g. LATEX/figures/}}`.

**Target:** `{{JOURNAL / CLASS — e.g. MDPI Remote Sensing, mdpi.cls}}`. The journal's
class and style files are vendored unmodified; don't edit them to fix a layout
problem.

**Build:** `{{BUILD COMMAND — e.g. latexmk -pdf main.tex, run from LATEX/}}` is the
single command that builds the PDF. It must finish with no undefined references or
citations. `{{PDF IN GIT — e.g. not committed, or committed at each submission}}`.

**Bibliography:** `{{BIB TOOL — biber + biblatex, or bibtex}}` with one file,
`{{BIB FILE — e.g. LATEX/bib/references.bib}}`. Keys follow
`{{KEY STYLE — e.g. authorYEARword}}`.

**Generated content:** numbers reported in the text come from
`{{MACROS FILE — e.g. LATEX/generated/results.tex}}`, `\input` by the main file and
written only by code (see `jupyter-conventions.md` or the analysis scripts). Figures
are produced by code; each `\includegraphics` carries a `% source:` comment naming
what produces it.

**Records:** a manuscript section or revision worth tracking is a `TASK-###`
(category Documentation, or Analysis where it needs new results). Use cases
(`UC-###`) describe what the people using the results need to do with them; a claim
the paper must support can be a requirement it traces to.
