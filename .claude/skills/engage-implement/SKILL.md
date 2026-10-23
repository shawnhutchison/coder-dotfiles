---
name: engage-implement
description: Implementation stage of Engage (draft): build the approved plan.md with workers, or fix the must-fix findings from the previous round. Runs in a loop with engage-verify and engage-review. Use when the engage skill reaches Implementation, or when the user asks to build or fix a ticket that has a plan.md.
---

# Stage: Implementation (draft)

Status: draft. The user has not defined this stage in detail yet. Follow the minimum protocol, follow `plan.md`'s build plan, and treat the candidate steps as defaults the user can change.

Implementation, Verify and Review run as a loop. Round 1 builds the plan. Each later round fixes the showstoppers from the previous round's Verify and Review. The goal is to converge on a solution that passes, not a perfect one.

This stage runs inside the factory. Do not stop for the user except on the conditions in `~/.claude/skills/engage/SKILL.md`.

## Minimum protocol

- **Entry.** Round 1: Planalysis is complete. Round n > 1: `findings.md` has items marked `fix` for this round. Feedback round: `findings.md` has `feedback r<k>` items marked `fix`, and only those are built.
- **At entry**, re-fetch the ticket and compare it with `ticket-snapshot.md`. If the asks or comments changed, stop and show the user the change before you build.
- Set `round` in `state.md`. Workers write reports to `rounds/<n>/`.
- Every worker brief includes `~/.claude/skills/engage/reference/standing-rules.md` and `plan.md`'s out-of-scope list.
- **Exit.** Every worker reported DONE, and the tests for the touched code pass. Then move to Verify without waiting for "Engage.", unless round 1 has a design pass. The user can stop the loop at any time.

## Design pass

This runs once, after the round 1 build, when `plan.md` says `Design pass: yes`. It is the factory's one planned stop. It moves live visual iteration to the point where it is cheapest: after the build, before Verify, Review and the PRs.

1. Confirm the dev server serves the code on disk. Send the user the URL of each state, with a screenshot of each, in one message. Set `stage_status: waiting`, `waiting_on: user` and `focus: Design pass`.
2. Start one design worker in the frontend repo. Its brief:
   - Apply each visual change the user asks for, then check it in the browser. Take a screenshot or measure with `getBoundingClientRect`. Report it as done only after that check.
   - Run no test suites during the pass. Verify runs them afterward.
   - Follow the binding design source and the user's newest word. When the two conflict, the user's word wins. Record each such conflict as a decision.
3. Relay each user request to the worker as a numbered update in `rounds/1/design-pass.md`. Check every update that removes or changes displayed data against the acceptance criteria, and tell the user at once if it breaks one.
4. The user's "Engage." ends the pass. Close the design worker, record the pass in `plan.md`, and move to Verify.

On OT-916, roughly 60 live design requests went to an implementer that was also running test suites. It fell behind, and nobody measured the page. One focused worker that checks every change in the browser avoids both problems.

## Candidate steps, from past tickets

**Round 1**
- Run the frontend and backend implementers in parallel against `contract.md`. The backend implementer owns the contract and marks each item confirmed. The frontend implementer re-reads it before finishing. On OT-916 and OT-964 this gave zero contract defects.
- For a UI ticket, build to the binding design source named in `plan.md`. Do not stop for visual approval. Verify compares the result against the design and saves screenshots of every state for the PR, and the user judges the visuals there.
- When the build has to drop or change displayed data, check the change against the acceptance criteria and record it in `plan.md` as a decision. On OT-916 a design update silently removed an acceptance criterion.
- Put optional visual polish on a side branch with a timebox. The OT-916 bee animation took several rounds and was then reverted.

**Round n > 1**
- The fixer gets only the items marked `fix` for this round, each with file, line, symptom and the test to write. Judge it only against that list, plus regressions.
- A finding at `Tries` 2 has failed two fixes. Before changing code again, the fixer writes the one sentence both fixes assumed, runs one check that would come out differently if that sentence were false, and reports the result.
- When a correction changes a running worker's task, stop the worker first (`herdr agent send-keys <name> esc`), then send the change. A correction that arrives after the worker acted costs a redo.

**Before Verify**
- Confirm the dev server serves the code on disk. After a branch switch, restart the app's Tilt resource. A stale Vite server caused four false bugs on OT-916.
