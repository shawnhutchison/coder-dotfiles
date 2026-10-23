---
name: engage-feedback
description: Feedback stage of Engage: after Ship, collect review feedback on a ticket's draft PRs (GitHub review comments, PR comments, notes the user gives in chat), triage it, run Implementation, Verify and Review rounds on just those changes, and ship again to the same branches. Use when the user says they reviewed or commented on a ticket's PRs, asks to address PR feedback, or runs /engage on a shipped ticket.
---

# Stage: Feedback

The user reviews the draft PRs on GitHub. Their comments, and any teammate's, come back through this stage. Each feedback round fixes only what the feedback asks for, then ships again. The factory rules still apply: stop for the user only on the conditions in `~/.claude/skills/engage/SKILL.md`.

## 1. Collect

For each PR listed in `ship/commits.md`:

```
gh pr view <number> --repo RoadRunnerEngineering/<repo> --json reviews,comments,url
gh api --paginate repos/RoadRunnerEngineering/<repo>/pulls/<number>/comments
```

Keep only comments newer than the last feedback round. Each round's file records its cutoff time. Add any notes the user gave in chat.

Read CI too: `gh pr checks <number> --repo RoadRunnerEngineering/<repo>`. Classify each failure before you act on it:

- A failure in code this PR changed becomes a `feedback r<k>` finding.
- A failure in code this PR did not touch: check whether the base moved with `git merge-base --is-ancestor`, and report a stale base.
- A failure that passes on rerun elsewhere is a flake. Report it.

Rerun nothing without the user's go.

If nothing is new, say so in one line and stop.

## 2. Triage

Set `stage: feedback` and increase `feedback_round` in `state.md`. Write `feedback/round-<k>.md` with one row per comment: author, `path:line`, link, what it asks, verdict, change.

- **The user's own comments are instructions.** Do them. Ask only when a comment is ambiguous in a way that changes the work, conflicts with another comment, or reverses a decision in `plan.md`.
- **A teammate's comment gets a verdict with evidence**: who wrote the code in question, how the repo does it elsewhere, with a usage count, and the cost of the change. Default to agreeing when the change simplifies the code or aligns it with the repo's convention. A comment you would push back on gets no code change. It gets a drafted reply with the evidence, so the user can decide when they read the PR.
- **A question** gets a drafted reply and no code change.
- **A request outside the ticket's scope** gets a drafted reply that proposes a follow-up ticket.

Add each agreed change to `findings.md` with source `feedback r<k>` and disposition `fix`. Record new decisions in `plan.md`.

## 3. Run the loop on the feedback only

Re-fetch the ticket and compare it with `ticket-snapshot.md`, as at every stage entry.

- `engage-implement`: fix the `feedback r<k>` items and nothing else.
- `engage-verify`: the criteria those changes touch, plus a short regression pass over the rest.
- `engage-review`: only the diff since the last shipped commit in each repo (`ship/commits.md`).

The same exit rules and round cap apply.

## 4. Ship again

Invoke `engage-ship` in feedback mode, in this session. The user's request to handle the feedback is said here, and auto mode judges the push against it:

- Commit to the same branches and push. Do not open new PRs.
- Update a PR body only where what the PR does has changed.
- Leave the PRs in draft.

Save reply drafts to `feedback/replies-<k>.md`, each with its comment link. Do not post them.

## 5. Report

- Per comment: the verdict, and the commit that addressed it.
- The reply drafts the user may want to post.
- The comments still waiting on the user's decision.

Set `waiting_on: user` and `focus: PR review, feedback round <k> shipped`.

## Exit

Every new comment has a verdict, and every agreed change is pushed.
