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
- Set `stage: verify`, and `step` to `seed`, `run` or `evidence` as each part starts.
- **Seed the data from the orchestrator session.** The user approved the recipe's console writes there during Planalysis, and auto mode accepts that approval only in the session that runs the command. Open a Rails console in a Herdr pane of your own tab and create the records the recipe lists. If a worker later needs another write, it stops and reports it, and you run it.
- **Run.** Spawn a verifier worker so screenshots and logs stay out of your context. Its brief gives it:
  - the verify-ui skill;
  - the numbered criteria and the recipe from `plan.md`;
  - the probes below that apply, as numbered checks after the criteria;
  - `contract.md`;
  - `~/.claude/skills/engage/reference/standing-rules.md`.

  From round 2 on, verify the failed criteria plus a regression pass, not everything again. In a feedback round, verify the criteria the feedback changes touch, plus a short regression pass.
- **Output.**
  - `rounds/<n>/verify.md`: PASS, FAIL or INCONCLUSIVE per criterion, a "Data changed" list and a "Skill friction" list. A PASS cites the screenshot, response or DB read that shows the end state. Inconclusive is not a pass.
  - For a UI ticket, a screenshot of every state the criteria cover, compared against the binding design source. Differences from the design are findings only when they break a criterion or a decision in `plan.md`. Ship links the screenshots in the PR.
  - Each failure goes into `findings.md` with source `verify r<n>`.
  - Each repo's tree id for the code this run checked, computed as in `engage-review`, "Record the tree id". Ship ships only a tree that a passing Verify recorded.
  - New ways to put records into a state go into `~/.claude/tickets/recipes/<area>.md`.
  - When `plan.md` says `Watch after deploy: yes`, fill its watch list: each log line or event the change adds that is the only signal of a failure, with the Datadog query that finds it. Code that rescues, logs and continues always goes on the list. QA runs these queries after the deploy.
- **Check the evidence.** Before exit, a second worker (sonnet, medium) opens each file a PASS cites and downgrades an unsupported PASS to INCONCLUSIVE. Rerun an inconclusive criterion once, with the gap named. If it is still inconclusive, Ship lists it under "Not verified". Past verifiers took API shortcuts and claimed the UI could not do a step, so a PASS is not accepted on the verifier's word.
- **Exit.** Every criterion passes, or a decision in `plan.md` defers it, or it stays inconclusive after one rerun. Failures go to Implementation as next round's fixes. Then move to Review.

## Probes

Past QA and acceptance testers found these defect classes after developers called the work done, on 54 of 148 tickets. Give the verifier each probe that applies.

- **Reload and second tab.** For stateful features, walk real records through every state, once without reloading and once with a reload after each step. Repeat one change from a second tab opened before it.
- **Edge values.** For each new input or field, try empty, null from the API, zero, a decimal that rounds, the longest realistic text, a past date, a duplicate, and two validation errors at once.
- **Other actors.** Run one criterion as a user without the permission, and one under masquerade when the app has it.
- **Real-size lists.** For each list, dropdown or search the change touches, use more data than one page holds and pick an item past the first page. Record each new endpoint's response time.
- **Visible text.** Compare every string the change shows with the ticket and the design, word for word, including case and product names.
- **Neighbors.** In round 1 too, rerun the behavior next to the change: the old path of a changed filter, the other states of a changed status, the core flows after an upgrade.

## Candidate steps, from past tickets
- Verify through the UI the ticket changes. When a verifier says the UI cannot do a step, check that claim before you accept an API shortcut.
- Record evidence video at 1920x1080 with device scale factor 1. Record the demo video once, at the end of the loop, on the final code.
- Known open items in verify-ui are in `~/.claude/tickets/OT-964/verify-ui-skill-review.md`. They belong in verify-ui itself, not in this stage.
