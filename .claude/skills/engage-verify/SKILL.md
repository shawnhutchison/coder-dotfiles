---
name: engage-verify
description: Verify stage of Engage (draft): check a round of ticket work against the acceptance criteria and verification recipe in plan.md, using the verify-ui skill through a verifier worker, and record showstoppers in findings.md. Use when the engage skill reaches Verify, or when the user asks to verify a ticket that has a plan.md.
---

# Stage: Verify (draft)

Status: draft. The user has not defined this stage in detail yet. The verify-ui skill does the checking. This stage gives it the ticket's criteria, the verification recipe and the rules, and it records the result.

Verify looks for showstoppers: an acceptance criterion that fails, an error the user would see, or wrong data written. The goal is a solution that passes. It is not a polish review.

## Minimum protocol

- **Entry.**
  - Implementation for this round is done.
  - No pending decision would change behavior. Do not verify scope that is about to change: OT-964's first final verify was thrown away.
  - `plan.md` has the verification recipe.
- **Seed the data from the orchestrator session.** The user approved the recipe's console writes there during Planalysis, and auto mode accepts that approval only in the session that runs the command. Open a Rails console in a Herdr pane of your own tab and create the records the recipe lists. If a worker later needs another write, it stops and reports it, and you run it.
- **Run.** Spawn a verifier worker so screenshots and logs stay out of your context. Its brief gives it:
  - the verify-ui skill;
  - the numbered criteria and the recipe from `plan.md`;
  - `contract.md`;
  - `~/.claude/skills/engage/reference/standing-rules.md`.

  From round 2 on, verify the failed criteria plus a regression pass, not everything again. In a feedback round, verify the criteria the feedback changes touch, plus a short regression pass.
- **Output.**
  - `rounds/<n>/verify.md`: PASS, FAIL or INCONCLUSIVE per criterion, a "Data changed" list and a "Skill friction" list. A PASS cites the screenshot, response or DB read that shows the end state. Inconclusive is not a pass.
  - For a UI ticket, a screenshot of every state the criteria cover, compared against the binding design source. Differences from the design are findings only when they break a criterion or a decision in `plan.md`. Ship links the screenshots in the PR.
  - Each failure goes into `findings.md` with source `verify r<n>`.
  - Each repo's tree id for the code this run checked, computed as in `engage-review`, "Record the tree id". Ship ships only a tree that a passing Verify recorded.
  - New ways to put records into a state go into `~/.claude/tickets/recipes/<area>.md`.
- **Check the evidence.** Before exit, a second worker (sonnet, medium) opens each file a PASS cites and downgrades an unsupported PASS to INCONCLUSIVE. Rerun an inconclusive criterion once, with the gap named. If it is still inconclusive, Ship lists it under "Not verified". Past verifiers took API shortcuts and claimed the UI could not do a step, so a PASS is not accepted on the verifier's word.
- **Exit.** Every criterion passes, or a decision in `plan.md` defers it, or it stays inconclusive after one rerun. Failures go to Implementation as next round's fixes. Then move to Review.

## Candidate steps, from past tickets

- For stateful features, run lifecycle walks: move real records through every state without reloading the page. The OT-964 stale-tab walk found a dialog that reopened itself, which unit tests missed.
- Verify through the UI the ticket changes. When a verifier says the UI cannot do a step, check that claim before you accept an API shortcut.
- Record evidence video at 1920x1080 with device scale factor 1. Record the demo video once, at the end of the loop, on the final code.
- Known open items in verify-ui are in `~/.claude/tickets/OT-964/verify-ui-skill-review.md`. They belong in verify-ui itself, not in this stage.
