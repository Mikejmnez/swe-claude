---
paths:
  - "**/*.tex"
  - "**/*.bib"
  - "**/latexmkrc"
  - "**/.latexmkrc"
---

# LaTeX rules

Loaded when a `.tex` or `.bib` file is read or edited. Project-level choices (main
file, build command, bibliography tool) are in the project's `CLAUDE.md` Conventions
section, from `latex-conventions.md`. Voice and register for manuscript prose follow
the user's global rules; they are not repeated here.

- **Every reported number comes from a generated macro.** Results appear in the text
  as commands (`\rmseModis`) defined in the generated macros file, which code writes —
  never as a literal typed into the prose. Don't edit the generated file by hand, and
  don't replace a macro with its current value. A number that has no macro yet gets a
  `[[RESULT: …]]` placeholder, not a value.
- **Every figure has one source.** Figures are produced by a script or notebook and
  never edited by hand. Next to each `\includegraphics` put a comment naming what
  produces it: `% source: notebooks/fig03_orbit_position.py`. A figure with no named
  source is a gap to report, not to fill in.
- **One sentence per line**, so a diff shows the sentence that changed. Don't reflow
  paragraphs that you are not otherwise changing.
- **Structure:** one main file that `\input`s one file per section. New material goes
  in the section file it belongs to, not in the main file.
- **Labels and references:** every figure, table, section and equation that is
  referenced has a `\label` with a type prefix (`fig:`, `tab:`, `sec:`, `eq:`), and is
  referenced with `\ref`/`\cref`, never by a hand-typed number.
- **Citations:** cite only keys that exist in the `.bib` file. A source you cannot
  find gets `[[CITE: …]]`, never an invented key or an entry written from memory.
  Don't reformat or reorder existing `.bib` entries unless asked.
- **The build is the check.** After editing, run the project's build command. An
  undefined reference, undefined citation, or multiply-defined label is a failure to
  fix, not a warning to report and leave.
- **Build products stay out of git** (`*.aux`, `*.log`, `*.bbl`, `*.blg`,
  `*.fdb_latexmk`, `*.fls`, `*.out`, `*.synctex.gz`, `*.toc`, `*.bcf`, `*.run.xml`).
  Whether the PDF itself is committed is the project's choice.
