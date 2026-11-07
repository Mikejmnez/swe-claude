<!-- CONTRACT: WHY things are the way they are. Never a log of what happened (that's
     git history / ai-plans/) — only calls that could plausibly have gone another way,
     with the reasoning captured so it isn't re-litigated from scratch in six months. -->

# Decisions

Convention: `ADR-###`, sequential, never renumbered. A superseded decision stays in
the file with `Status: Superseded by ADR-0XX` — the reasoning that led somewhere wrong
is often as useful later as the reasoning that led somewhere right.

---

## ADR-EXAMPLE — Use a time-limited link, not a one-time code, for password reset

*(delete this section once you've seen the shape)*

**Date:** YYYY-MM-DD
**Status:** Accepted

**Context:** Password reset needed a mechanism that works from any device, including
one the user isn't currently signed in on.

**Decision:** Emailed link with a signed, expiring token, rather than a numeric code
entered back into the original device.

**Alternatives considered:**
- Numeric code — simpler to implement, but assumes the user is on the same device
  they requested from, which broke for a chunk of support tickets historically.

**Consequences:** Reset flow now depends on transactional email deliverability, which
becomes a new failure mode to monitor (see IC-EXAMPLE if a related constraint exists).

**Related:** FR-EXAMPLE, UC-EXAMPLE

---

## ADR-001 — Under `-r`, records stay on the records repo's `main`; no branches there

**Date:** 2026-11-06
**Status:** Accepted

**Context:** `link-swe-claude.sh -r` keeps a project's `ai-docs/`, `ai-plans/` and
`CLAUDE.md` in one folder of a separate records repo, shared by all projects, and
excludes the links from the project's git. The "Branch & working-tree discipline" rule
in `planning-rules.md` then breaks in two ways: the project's `git status` cannot see
the records, so the clean-tree check misses them; and a log entry or plan lands in the
records repo, so "on that item's branch" has no single meaning.

**Decision:** Code follows the existing rule in the project. Records are edited and
committed on the records repo's `main`, never on a branch, with commit messages that
name the project, the ID(s) and the project branch. The clean-tree check runs in both
repos, scoped in the records repo to the project's folder, found from the `ai-docs`
link target.

**Alternatives considered:**
- Mirror branches (same `mju/<slug>` in the records repo, merged with the project's) —
  matches a record change to its code's lifecycle, but the records repo is shared:
  a checkout there switches every project's records at once, so two projects (or two
  items) in progress fight over one working tree; and every item needs two branch asks.
- A records repo per project — would make mirror branches workable, but changes the
  layout TASK-001 built and the README documents.

**Consequences:** A record change and the code it describes are not in one branch or
one merge, so reverting a project branch does not revert its plan or log entry.
Records of abandoned work stay on the records repo's `main` (IDs are never reused, so
they are history either way). The clean-tree check now spans two repos and depends on
Claude noticing that `ai-docs` is a symlink.

**Related:** TASK-002, TASK-001; `planning-rules.md` "When records live in a separate repo"

---
