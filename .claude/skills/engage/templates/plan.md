# <KEY> plan: <Jira summary>

Status: draft | agreed <date>. Ticket: <type>, <points> pts, <status>, epic <EPIC>, labels <labels>. Track: <track>.

## Verdict

Up to five sentences: what we will build, how big it is, and the hard parts.

## User context

Every claim, constraint and preference from the user's kickoff message, one line each.

## Where it sits

| Ticket | Status | Owner | Relation | Branch or PR state |
|---|---|---|---|---|

## Asks

| # | Ask, in the ticket's words | Source | State today | Change |
|---|---|---|---|---|

## Sufficiency

From `reference/sufficiency.md`.

| # | Check | Gap | Resolution: asked, default or product question |
|---|---|---|---|

Signals of late change: <list, or none>.

## Behavior this changes

Each shipped rule or stored value the ticket changes, who signed off, and the migration story where stored values change.

## Decisions

- <date>, user: <decision>
- <date>, recommended, not confirmed: <decision the factory builds to>

## Open questions for the user

Questions the interview has not settled. This list must be empty or accepted by the user at "Engage.".

## Questions for product

| # | Question | Recommended answer | Built to | Sent |
|---|---|---|---|---|

## Out of scope

| Item | Owner ticket | Why |
|---|---|---|

## Review inputs

Reviewers get this section.

- Concurrent users:
- How the real client builds its requests:
- Endpoints in scope:
- Production and staging data for this feature:
- Inherited code that is out of scope:
- Glossary, for terms the frontend and backend use differently:

## Design

Each source with its authority (binding or reference), date and author. The user's standing UI preferences.

## Environment and side effects

What dev and test actions touch outside the workspace, flags involved, and whether the dev DB is shared.

## Technical approach

Per repo: what changes and which existing code it reuses, with `path:line`. The convention followed for each kind of change, with its usage count. For a frontend and backend ticket, a summary of `contract.md`.

## Files likely to change

| File | Change | Why |
|---|---|---|

## Tests

| Seam | Regression it catches | Spec to follow | New or changed |
|---|---|---|---|

## Verification recipe

| # | Criterion | How to prove it | Data needed | How to create the data |
|---|---|---|---|---|

- Console writes the verifier needs:
- Tilt resources and URLs:
- Harness to reuse:
- External calls to avoid or stub:
- QA hand-off:
  - Where testers test: this workspace before merge, or a shared environment after deploy:
  - Apps and URLs testers open:
  - Test users, and the permission each one needs:
  - Flags, and the state each test needs:
  - Seed commands, and the IDs they create:
  - Dev limits that look like bugs, such as blocked external calls or slow pages:
- Watch after deploy: yes | no
  - Watch list, from Verify: each log line or event that is the only signal of a failure, with the Datadog query that finds it:

## The factory will stop for

Points step 9 could not settle. Empty when the factory can run to draft PRs without the user.

## Build plan

- Branches and bases, worktrees, PR base:
- Release: merge order, deploy order, holds, run-once tasks and their environments, hotfix flow:
- Design pass: yes | no
- Workers, order, and what runs in parallel:
- Estimate, against sibling tickets:

## Sources

What each source said, one line each.
