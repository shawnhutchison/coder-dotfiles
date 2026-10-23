---
name: engage-feedback
description: Feedback stage of Engage: after Ship, collect everything new on a ticket (GitHub review comments, PR comments, CI results, tester reports and changed asks in Jira, base-branch moves, notes the user gives in chat), triage it, run Implementation, Verify and Review rounds on just those changes, and ship again to the same branches. Use when the user says they reviewed or commented on a ticket's PRs, asks to address PR or QA feedback, or runs /engage on a shipped ticket.
---

# Stage: Feedback

Everything that arrives after Ship comes through this stage: the user's PR review, teammates' comments, CI, testers' reports and changed asks in Jira. Each feedback round builds only what the round needs, then ships again. The factory rules still apply: stop for the user only on the conditions in `~/.claude/skills/engage/SKILL.md`.

Set `stage: feedback`, and `step` as each step starts. Feedback usually arrives a day or more after Ship, so earlier workers' prompt caches are cold. Check each worker's `last_active` before any reuse (`~/.claude/skills/engage/reference/workers.md`, "Close and reuse").

## 1. Collect

Collect what is newer than the last round's cutoff. Each round's file records its cutoff time.

- **PRs.** For each PR in `ship/commits.md`:

  ```
  gh pr view <number> --repo <owner>/<repo> --json reviews,comments,url,mergedAt
  gh api --paginate repos/<owner>/<repo>/pulls/<number>/comments
  ```

- **CI.** `gh pr checks <number> --repo <owner>/<repo>`. Classify each failure before you act on it:
  - A failure in code this PR changed becomes a finding.
  - A failure in code this PR did not touch: step 2 checks whether the base moved.
  - A failure that passes on rerun elsewhere is a flake. Report it.

  Rerun nothing without the user's go.
- **The ticket.** Re-fetch it and run "Detect" in `~/.claude/skills/engage/reference/change-requests.md`. Testers and product post in Jira, not on the PR, so read every new comment and attachment.
- **The user's notes** from chat.

If nothing is new and no base moved, say so in one line and stop. When every PR has merged and the ticket is in QA, go to `engage-qa`, step 5.

## 2. Keep branches current

For each branch in `ship/commits.md`, check whether its base moved: `git merge-base --is-ancestor origin/<base> <branch>`. If it moved, merge the base forward in this session.

- Compare `git diff --stat origin/<base>...<branch>` with the stat recorded at the last ship. A ticket file that lost lines is a finding: past tickets lost changes in a merge.
- A conflict that changes behavior is factory stop 3. Resolve the others.
- Name any other ticket's branch that is based on this one. It needs the same step.

Run Verify's regression pass on a merged branch before step 5 pushes it.

## 3. Triage

Increase `feedback_round` in `state.md`. Write `feedback/round-<k>.md` with one row per item: source, author, `path:line` or link, what it asks, class, verdict, change.

- **The user's own comments are instructions.** Do them. Ask only when a comment is ambiguous in a way that changes the work, conflicts with another comment, or reverses a decision in `plan.md`.
- **A teammate's comment gets a verdict with evidence**: how the repo does it elsewhere, with a usage count, and the cost of the change. "Changes requested" or "blocking" is required. "Nit" or "follow up" is optional. Default to agreeing, and make a requested move to the repo's standard structure even when it is large: past reviewers' structural requests were adopted every time. Push back only with a fact, such as a code path, a query result or the ticket text. Pushback gets a drafted reply and no code change.
- **A tester's report, a changed ask, a question or an out-of-scope request** gets its class and handling from `~/.claude/skills/engage/reference/change-requests.md`.

Add each item to build to `findings.md` with source `feedback r<k>` and disposition `fix`. Record new decisions in `plan.md`.

## 4. Run the loop on the feedback only

- `engage-implement`: fix the `feedback r<k>` items and nothing else.
- `engage-verify`: the criteria those changes touch, plus a short regression pass over the rest.
- `engage-review`: only the diff since the last shipped commit in each repo (`ship/commits.md`).

The same exit rules and round cap apply.

## 5. Ship again

Invoke `engage-ship` in feedback mode, in this session. The user's "Engage." covers pushes to the same branches:

- Commit to the same branches and push. Do not open new PRs.
- Rewrite a PR body from the final diff where what the PR does has changed.
- Leave the PRs in draft.

When the round changed behavior that QA already passed, write `qa/delta-<k>.md` as `change-requests.md` describes. Save reply drafts to `feedback/replies-<k>.md`, each with its comment link. Do not post them. Update `ticket-snapshot.md`.

## 6. Report

- Per item: the class, the verdict, and the commit that addressed it.
- The reply drafts, the new-ticket drafts and any QA delta the user may want to post.
- The items still waiting on the user's decision.

Set `waiting_on` to `user`, or to `testers` while the ticket is in QA, and set `focus` to what is pending.

## Exit

Every new item has a verdict, every agreed change is pushed, and every branch contains its base with the diff intact.
