<!-- Shape for analysis plans written to ai-plans/analysis-<slug>-plan.md by
     /plan-task when the task's category is Analysis. This file itself is never a real
     plan — copy the shape, don't edit this one. Differs from _template-task.md in
     what "done" means: an analysis is done when its outputs exist, were produced by
     code that re-runs from a clean checkout, and say what they say — not when the
     code looks finished. -->

# Analysis Plan: {{ANALYSIS TITLE}}

**Task:** TASK-###
**Status:** Draft | In Review | Approved | In Progress | Done
**Created:** {{DATE}}

## Question

The question this analysis answers, in one or two sentences, phrased so the answer
could come out either way.

## Related requirements / use cases / decisions

- UC-### / FR-### / NFR-### — what this serves (e.g. the use case whose user needs
  the result)
- ADR-### — earlier choices this analysis must respect (dataset version, thresholds)

`None` is a valid answer.

## Data

| Input | Source & version | Location | Notes |
|---|---|---|---|
| ... | ... | ... | subsetting, quality flags applied |

Anything not yet available is listed here as missing, not assumed.

## Method

Steps, and the choices inside them. A choice that constrains later work (a threshold,
a season definition, a filtering rule) is flagged here as a candidate `ADR-###`.

1. ...
2. ...

## Outputs

| Output | Kind | Written to | Produced by |
|---|---|---|---|
| Figure N | figure | `LATEX/figures/...` | `notebooks/...` |
| `\macroName` | number in text | generated macros file | `notebooks/...` |
| ... | table / derived data | ... | ... |

Every figure and every number that reaches the manuscript appears in this table.

## Re-run

The exact command(s) that regenerate every output above from a clean checkout, in
order. "Done" requires that these succeed.

## Verification

How to tell the result is right, not just produced: a sanity check against a known
value, a comparison with a previous run, a synthetic case with a known answer, a
check that sample sizes are what they should be.

## Risks

What could make the result wrong without the code failing — a silent data gap,
a unit mismatch, an off-by-one in time windows.

## Open questions

Genuine unknowns — not filled with a plausible guess. Values not yet measured are
written "unmeasured" or `[[RESULT: …]]`, never estimated.

- ...
