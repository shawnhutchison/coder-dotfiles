# <KEY> findings

One row per finding from Verify or Review, kept across rounds. Reviewers and fixers read this file instead of old reports. A finding with a final disposition is not raised again.

| ID | Source | Finding | `path:line` | Evidence | Level | Disposition | Round | Tries | Reason |
|---|---|---|---|---|---|---|---|---|---|

- **Source**: `verify r<n>`, `review r<n>`, `spec r<n>` or `feedback r<k>`.
- **Evidence**: the failing spec, repro, screenshot or response, or "none".
- **Level**: `1 said` (a claim only), `2 line` (points at code), `3 traced` (follows the call path), `4 ran` (a spec or command shows it), `5 app` (seen in the running app). Must-fix needs 4 or 5.
- **Disposition**: `fix` (must-fix, goes to the next round), `fixed`, `defer <ticket>`, `reject`.
- **Tries**: how many fix rounds have addressed it. A finding that comes back adds one.
- **Reason**: why, in one line. For `reject`: out of scope, not reachable by the real client, not introduced or newly reached by this PR, evidence below level 4, or not from this round.
