<!-- CONTRACT: actor-driven flows through the system. Each use case is what ties
     functional requirements together into something a real user actually does.
     Delete the _EXAMPLE_ use case once you've seen the shape. -->

# Use Cases

Convention: `UC-###`. Each use case follows the template below. Link related `FR-###`
/ `NFR-###` IDs at the bottom so `/trace` can find them in both directions.

---

## UC-EXAMPLE — Reset a forgotten password

*(delete this section once you've seen the shape)*

**Actor(s):** Registered user who cannot log in

**Trigger:** User selects "Forgot password" on the login screen

**Preconditions:** User has an account with a verified email address

**Main flow:**
1. User submits their email address
2. System sends a time-limited reset link to that address
3. User follows the link and sets a new password
4. System confirms the change and signs the user in

**Alternate / exception flows:**
- Email address not on file → system shows a generic "if that address exists..."
  message (no account enumeration)
- Link expired or already used → system shows an error and offers to resend

**Postconditions:** User's password is updated; all other active sessions are
invalidated

**Related requirements:** FR-EXAMPLE, NFR-EXAMPLE (add real IDs once they exist)

---

## UC-ANALYSIS-EXAMPLE — Compare satellite SST products against in-situ matchups

*(delete this section once you've seen the shape — a research-flavoured example of the
same template)*

**Actor(s):** Ocean scientist evaluating which SST product to use in a study

**Trigger:** Scientist needs an error estimate for each product over their region and
period

**Preconditions:** Matchup files for the period exist; product versions are recorded

**Main flow:**
1. Scientist selects region, period and products
2. System computes per-product bias and standard deviation against the matchups
3. System produces the comparison figure and a table of the statistics
4. Scientist cites the figure and numbers in the manuscript

**Alternate / exception flows:**
- Too few matchups in a cell → that cell is masked and the count is reported, not
  interpolated
- Product version differs from the recorded one → run stops and reports the mismatch

**Postconditions:** Figure and numbers regenerate identically from a clean checkout

**Related requirements:** FR-EXAMPLE, NFR-EXAMPLE (add real IDs once they exist)

---

<!-- Copy the template above for each new use case. Sequential UC-### heading,
     same subsection order, so /trace can parse it. -->
