# Ticket kinds

Planalysis step 2 picks one kind and writes its slug into `state.md`'s `kind`. The kind sets what to pin down, what to deliver, and what may be written.

| Slug | Kind | Pin down | Deliverable | Writes allowed | Track |
|---|---|---|---|---|---|
| `feature` | Feature | Asks, design authority, contract, dependencies, operating profile | Working code in draft PRs | Code, after "Engage." | standard or project |
| `bug` | Bug (often MoB) | A reproduction that has shown the broken state twice, the exact failing path, logs and data, and three to five ruled-out or open hypotheses | Fix plus a test that fails before it | Code, after "Engage." | quick or standard |
| `techdebt` | Tech debt | The current cost, measured, and what "done" looks like | Change plus a before and after measurement | Code, after "Engage." | quick or standard |
| `devops` | Devops or infra | Which environments, rollout and rollback, who must approve | Change plus a rollout plan | Code, after "Engage." | standard |
| `spike` | Spike | What exists, analogous patterns, constraints | What exists, the gaps, where a change would go and why | None | answer |
| `triage` | Incident triage | The exact failing path, logs, data, one-off or systemic | Cause with evidence, cleanup, lasting fix | None | answer |
| `deploy-check` | Post-deploy check | Deploy time, the traffic the change touches | Comparison with the day before, a cause for each change, limits | None | answer |
| `question` | Behavior or impact question | The call path across repos, flags, linked tickets | A `file:line` trace, flag-gated changes, release risk, then a run that confirms it | None | answer |
| `grooming` | Grooming | The ticket, its siblings, dependency state | A delta or a rewrite in the ticket's existing format, points, staffing | Jira, on explicit go | answer |
| `estimate` | Estimate | Refinement answers, the code, sibling points | Points in the estimate format below | Never set points unasked | answer |
| `pr-review` | Review of someone else's PR | Its place in the pipeline, the consumer's use case | Collisions, the better design per concern, the smallest resolution | None | answer |

## Labels

- **MoB** (maintenance of business): users asked for it. Usually self-contained. Reproduce with the reporter's own example first.
- **TechDebt**: usually self-contained. Coordination with other engineers is possible but rare.
- **No label**: project work. The epic places it, and sibling epics with the same name prefix belong to the same project.

## Devops repos

Devops work is not in a default workspace. Clone the repo it needs into `~/workspace` (`reference/repos.md`).

## Estimate format

- Points.
- Basis: the description only, or the code read.
- Coverage: frontend, backend or both, and one engineer or two.
- The sibling tickets used to calibrate, with their points.
- What would raise the estimate.
- Split candidates.
- "I don't know" where an open question blocks the estimate.
