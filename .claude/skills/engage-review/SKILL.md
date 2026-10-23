---
name: engage-review
description: Review stage of Engage (draft): run a style pass (/simplify, style, test audit) and then /code-review on a round of ticket work, triage findings to showstoppers only, and decide whether the loop goes another round or moves to Ship. Use when the engage skill reaches Review, or when the user asks to review a ticket branch that has a plan.md.
---

# Stage: Review (draft)

Status: draft. The user has not defined this stage in detail yet. Review is two passes: a style pass, then a code review. It reports showstoppers only. The goal is to converge on a mergeable solution.

## Minimum protocol

- **Entry.** Verify for this round has passed, or its failures are already queued as fixes.
- **Style pass.** Run `/simplify`, then an organization and style pass against `~/.claude/skills/engage/reference/standing-rules.md`, then a test audit against `plan.md`'s Tests table: a test outside the table is a finding, unless a fix needed it. The style worker applies small changes itself and reports larger ones as proposals.
- **Code review.** Run `/code-review` on the code after the style pass, so it reviews the final shape. Pass the diff as a written instruction, for example "the working tree against local OT-916". Passing a base branch as a PR target reviewed the wrong diff twice on OT-964.
- **Spec review.** In parallel with `/code-review`, a spec worker reads the diff against `plan.md`'s Asks, Decisions and Out of scope, and against `contract.md`. It reports asks that are missing or partial, behavior no ask covers, and code that contradicts a decision, each citing the plan row. Unrequested behavior is must-fix. Verify cannot see added scope, and on OT-916 a criterion was lost this way.
- **Reviewer inputs.** Every reviewer brief opens with `plan.md`'s Verdict as the intent, then: "Challenge the execution, not the intent. If nothing is must-fix, say so." Give reviewers `plan.md`'s operating profile, out-of-scope list and glossary, plus `findings.md`, and tell them not to re-raise decided items. On OT-945 missing scope facts drove most of the 13 review passes.
- **Triage.** Read every finding and record it in `findings.md` with its evidence level (`~/.claude/skills/engage/templates/findings.md`). A finding is must-fix only when all of these hold:
  - its evidence is at level 4 or 5: it was run, or seen in the app;
  - it is in this ticket's scope;
  - the real client can reach it;
  - this PR introduced it, copied it, or newly makes it reachable.

  Use the user's buckets: "Absolutely fix", "You could fix it if you wanted to", "Don't worry about it". Judge on merits first. If time pressure changes the call, show both views.
- **Later rounds.** From round 2, review only the diff since the previous round's tree id, and mark each `fix` finding of that round resolved, unresolved or regressed. Rerun the full style pass and `/code-review` only if the round added behavior or changed more than about 150 lines. A new finding outside the round's diff is `reject`, "not from this round". On Matt Pocock's projects, a review loop that re-reviewed everything ran for four hours.
- **Feedback rounds.** Review only the diff since the last shipped commit in each repo (`ship/commits.md`).
- **Record the tree id.** At exit, record each repo's tree id in `rounds/<n>/review.md`, so Ship can check it ships exactly this code. This builds the id from a copy of the index, so the real index, status and stash stay untouched:

  ```
  i=~/.claude/tickets/<KEY>/rounds/<n>/<repo>-review.index
  cp "$(git -C ~/workspace/<repo> rev-parse --git-dir)/index" "$i"
  GIT_INDEX_FILE="$i" git -C ~/workspace/<repo> add -A
  GIT_INDEX_FILE="$i" git -C ~/workspace/<repo> write-tree
  ```
- **Exit.**
  - Must-fix items exist: they go to Implementation as the next round.
  - None remain, and the style pass changed code: run Verify's regression pass on the new tree, then invoke `engage-ship`. Review does not run again for its own style changes.
  - None remain, and no code changed: invoke `engage-ship` at once. Do not wait for the user. The user reads the full diff on GitHub in the draft PRs. On OT-916 that read found more structural issues than three AI reviews, so Feedback exists to take it.
- **Round cap.** If round 3 still ends with must-fix items, stop the factory and show the user the open findings. This is one of the factory's stop conditions.

## Candidate steps, from past tickets

- Scale by diff size. Below about 150 changed lines in a repo, one worker does style and review together.
- After a fix round that follows the style pass, rerun a short style pass over the files that fix touched. Polish regressions recurred on OT-964.
- Every new file, export or shared constant must have two or more users and a name that says what it returns. Otherwise inline it.
