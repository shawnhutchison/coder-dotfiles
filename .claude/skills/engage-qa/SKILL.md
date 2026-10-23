---
name: engage-qa
description: QA stage of Engage (draft): after Ship, keep the test environment on the shipped code, write the QA hand-off, answer testers without changing anything, route tester reports to Feedback, and check the change after it deploys. Use when a shipped ticket is ready for QA or acceptance testing, when the user runs /engage qa <KEY>, or when a tester asks about a ticket.
---

# Stage: QA (draft)

Status: draft, built from 148 past tickets and not yet run.

QA keeps the test environment right, gives testers what they need, and routes what they find. It changes no code itself: fixes go through `engage-feedback`. On past tickets, one in five failed its first QA. Testers lost days to stopped workspaces, wrong branches and missing setup, and asked for data, flags and users more often than for steps.

Testers may test in the workspace that built the ticket, before the PRs merge, or in a shared environment after a deploy. `plan.md`'s QA hand-off block says which.

## Entry

- Ship is complete.
- The ticket's status shows it is ready for QA or past it, or the user runs `/engage qa <KEY>`.

Set `stage: qa`, and `step` as each step starts.

## 1. Hold the test environment

When testers use this workspace:

1. Set `qa_hold: true` in `state.md`. No other ticket may switch this workspace's branches while it is set (`~/.claude/skills/engage/SKILL.md`, "Rules for every stage").
2. Check that each repo serves the shipped code. The ticket's branch is checked out, and its tree id matches the last ship in `ship/commits.md` (`engage-review`, "Record the tree id"). Every Tilt resource the recipe names is `ok`.
3. Run the recipe's migrations, seed and flag steps here if they have not run. Console writes run in this session. If auto mode refuses one, that is factory stop 1.

When testers use a shared environment, check that its deploy contains the PR's commits before you hand off.

## 2. Write the hand-off

Write `qa/handoff.md` from `plan.md`'s QA hand-off block:

- the apps and URLs to open;
- the test users and the permission each one needs, never credentials;
- a table of steps and expected results, numbered like the criteria;
- the seed commands and the IDs they created, and each flag's state;
- dev limits that look like bugs, such as blocked external calls or slow pages;
- Ship's "Not verified" list;
- the deploy order and any run-once tasks.

Label it a full replacement for a Jira comment. Do not post it. The user posts it. Set `waiting_on: testers`.

## 3. Answer testers

A tester's question gets an answer, not an action. Answer from `plan.md`, the recipe, the code and the running app. Use verify-ui when the answer needs the app. Save each answer to `qa/answers.md` as a draft the user can paste.

Change nothing unless the user asks. A console write for a tester runs in this session, on the user's go.

## 4. Route tester reports

When testers report results in Jira or in chat, run `engage-feedback`. It reads the ticket's comments, sorts each report with `~/.claude/skills/engage/reference/change-requests.md`, and builds, verifies and ships the reports that need code. It writes a QA delta when a round changes behavior QA already passed.

At the first tester report, set `metrics.qa_first_pass` to `pass` or `fail`.

## 5. Check the deploy

When every PR in `ship/commits.md` has merged and deployed:

- Check each run-once task from `plan.md`'s Release line, per environment. Ask the user before you run one.
- For infrastructure changes, read the plan or apply output per environment.
- When `plan.md` says `Watch after deploy: yes`, run the watch list's Datadog queries over the hours after the deploy, and compare them with the same hours the day before.

Write `qa/deploy-<date>.md`. A failure gets a drafted ticket, which the user files.

## Exit

QA and acceptance passed, every PR merged, and the deploy check ran or was not needed. Clear `qa_hold`, mark QA complete in `state.md`, and suggest `/engage reflect <KEY>`. The user can end the stage at any time.

## Workers

Tester reports arrive days after Ship, so every earlier worker's prompt cache is cold. Start fresh workers from their briefs (`~/.claude/skills/engage/reference/workers.md`, "Close and reuse").
