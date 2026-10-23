---
name: engage
description: Run a Jira ticket through Engage, a software factory of fixed stages (Setup and Planalysis with the user, then Implementation, Verify and Review in a loop, Ship to draft PRs, QA hand-off and support, Feedback rounds from PR review, testers and ticket changes, and Reflect), each stage its own engage-* skill, with the ticket's state kept in ~/.claude/tickets/<KEY>/state.md. Use when the user starts or resumes work on a ticket ("let's start OT-123", "/engage OT-123"), says "Engage." to approve a plan, asks where a ticket stands, says they reviewed a ticket's PRs, says a ticket is ready for QA, or names a stage of a ticket.
---

# Engage

Every ticket moves through the same stages. Each stage is its own skill with its entry rules, steps, outputs and exit rules. This skill routes to the right stage, keeps `state.md` current and handles "Engage.". It holds the shared files every stage uses: `framework.json`, `reference/` and `templates/` in `~/.claude/skills/engage/`.

**The factory model.** Setup and Planalysis are the interactive stages. Planalysis settles everything the build would otherwise stop for. After the user's "Engage.", the rest runs as a factory, with no further input, until the draft PRs are open. The user then reviews the PRs on GitHub. When the ticket is ready for QA, the QA stage hands it to testers. PR comments, tester reports and ticket changes all come back through Feedback, which runs rounds on just those changes.

| Stage | Skill | Runs | Status |
|---|---|---|---|
| Setup | `engage-setup` | once per Coder workspace | ready |
| Planalysis | `engage-planalysis` | per ticket, with the user | ready |
| Implementation | `engage-implement` | per round | draft |
| Verify | `engage-verify` | per round | draft |
| Review | `engage-review` | per round | draft |
| Ship | `engage-ship` | after the loop converges | ready |
| QA | `engage-qa` | after Ship, until QA and acceptance pass and the change is live | draft |
| Feedback | `engage-feedback` | per round of PR review, tester reports or ticket changes | ready |
| Reflect | `engage-reflect` | per ticket, when the user asks | ready |

`framework.json` holds the same map in machine-readable form, with every stage's numbered steps, the loops and the stop conditions. Status displays read it together with each ticket's `state.md`. Keep it in sync when a stage's steps change.

**The loop.** Implementation, Verify and Review run in rounds. Verify failures and must-fix Review findings start the next round. Both stages count showstoppers only, because the goal is to converge on a solution that passes. The loop ends when a round passes Verify and Review finds nothing must-fix. Ship follows at once.

**Changes.** A new or changed ask can arrive at any stage. Every stage handles it with `reference/change-requests.md`, which absorbs small changes, routes new scope to its own ticket, and stops the factory only for a reversal.

## When the factory stops for the user

**Planned stop.** A UI ticket can schedule one design pass in Planalysis. After round 1 builds, the factory pauses so the user can iterate on the visuals in the running app (`engage-implement`, "Design pass"). The user's next "Engage." ends the pass, and the factory resumes with Verify.

**Unplanned stops.** After "Engage.", stop and ask only when one of these holds:

1. A permission prompt only the user can answer, such as a console write that Planalysis did not get approved.
2. A change that `reference/change-requests.md` classes as a reversal: it undoes a decision in `plan.md` or a behavior already shipped.
3. A decision that changes behavior, where neither `plan.md` nor a recommended answer covers it.
4. The loop has not converged after three rounds.
5. An action that reaches outside the workspace beyond pushing branches and opening draft PRs.

Everything else goes into `plan.md` as a decision, and the factory continues. A stop message opens with the one call the user must make, then gives your pick, the evidence and the risk. Set `waiting_on: user` and `stop` to the condition's number, and keep the stop narrow. When the factory finishes, Ship reports the PR links and what the factory decided without the user.

## Auto mode

Every session runs in auto mode: the orchestrator, and every worker, which starts with `--permission-mode auto`. Auto mode judges each risky action against what the user said in the same session. Three things follow:

- Actions that need the user's word run in the orchestrator session, where the user spoke. These are the console writes the user approved during Planalysis, and Ship's commits, pushes and draft PRs, which the user's "Engage." approved. Never delegate them to a worker.
- The commands on the user's ask list (`rm`, `kill`, `chmod`, `sudo`, `docker` and the rest) prompt even in auto mode. Nobody watches a worker's pane, so they are banned outright (`reference/standing-rules.md`).
- When auto mode refuses an action, do not look for a way around it. A refusal that blocks the plan is factory stop condition 1.

**Draft stages** have not been defined with the user yet. Follow their protocol and `plan.md`'s build plan, and keep `state.md` current.

**Kinds without a build.** For the answer track (spike, triage, estimate, question, PR review), Planalysis produces the deliverable after "Engage.", and the ticket goes straight to Reflect.

## Org overlay

Engage is general and lives in a public repo. Rules that belong to one organization live in a private skill named `engage-org`, from that organization's plugin marketplace: repo conventions, the Jira workflow, team ownership, environments. When a skill whose name ends in `engage-org` is available, invoke it once at the start of each session that runs a stage, and follow it where it is more specific than Engage. Every worker brief includes the overlay files it names for the repos the worker touches. Without the overlay, read each repo's own `CLAUDE.md`, `AGENTS.md` and `CONTRIBUTING` files for its conventions.

## Commands

- `/engage <KEY>`: start or resume the ticket at its current stage. A new ticket starts Planalysis, whose first step checks Setup. A shipped ticket goes to Feedback, which collects new PR comments, CI results, tester reports, ticket changes and base-branch moves. When the ticket is ready for QA and QA has not started, QA runs next.
- `/engage status [<KEY>]`: print the status block below. Without a key, print one line per ticket folder that has a `state.md`: key, stage and step, `waiting_on`, and `updated`. Read-only.
- `/engage <stage> <KEY>`: go to a stage. If the current stage's exit rules are not met, say which ones and ask before you skip.
- `/engage qa <KEY>`: hand the ticket to QA, or answer a tester's question.
- `/engage setup`: run Setup for this workspace.

To run a stage, invoke its skill with the Skill tool. The stage skills can also be invoked directly.

Find the ticket key in this order: the command's arguments, the current git branch, `$CODER_WORKSPACE_NAME`. Workspaces are often reused for later tickets, so confirm a key that did not come from the arguments.

## Engage

"Engage." from the user approves Planalysis's plan. It applies when `stage_status` is `awaiting_engage`. Then:

1. Mark Planalysis `complete` in `state.md` and log it.
2. Start round 1 by invoking `engage-implement`.

That one "Engage." approves the whole factory run: the build, the loop, and Ship's commits, pushes and draft PRs. It also covers later feedback rounds, which push to the same branches. The only later "Engage." ends a design pass. The user can stop the factory at any time.

If questions are still open when the user says "Engage.", name them in one line and continue. That is the user's call.

## Where things live

The framework is versioned in the public coder-dotfiles repo. Never put secrets, internal URLs, MCP gateway URLs or customer data in a skill.

Everything the framework writes on a workspace goes under `~/.claude/tickets/`:

| Path | Content |
|---|---|
| `dev-setup.md` | Setup result for this workspace (`templates/dev-setup.md`) |
| `<KEY>/state.md` | Where the ticket stands (`templates/state.md`) |
| `<KEY>/ticket-snapshot.md` | The ticket's description and comments as last read |
| `<KEY>/plan.md` | Planalysis output and every later decision (`templates/plan.md`) |
| `<KEY>/contract.md` | API contract, for a frontend and backend ticket |
| `<KEY>/research/` | Planalysis worker reports |
| `<KEY>/briefs/` | Worker briefs (`templates/brief.md`) |
| `<KEY>/rounds/<n>/` | Implementation, verify and review reports for round n |
| `<KEY>/findings.md` | Every verify and review finding with its disposition (`templates/findings.md`) |
| `<KEY>/ship/` | Commit plans, shipped commits and PR bodies |
| `<KEY>/qa/` | The QA hand-off, tester answers, QA deltas and deploy checks |
| `<KEY>/feedback/` | Each feedback round's inputs, triage and reply drafts |
| `<KEY>/reflect/`, `<KEY>/reflect.md` | Reflect corpus and report |
| `recipes/<area>.md` | How to put records into each state, shared across tickets |

Never write these to `/tmp`, which is cleared every night, or into a repo.

## state.md

`state.md` is the one source of truth for where the ticket stands. Status displays read its frontmatter together with `framework.json`, so keep the keys and values exactly as `templates/state.md` defines them, and use stage and step ids from `framework.json`. Update it:

- when a stage, a step or a round starts or ends;
- when the focus changes;
- when you start or stop waiting on the user, product, testers or a worker;
- when a worker starts, reports, goes idle or closes, in `workers`.

Set `orchestrator` to this session's name from ListAgents when you create or resume the ticket. `focus` is one line: what is being worked out right now. `updated` and each log line take a UTC timestamp from `date -u +%FT%TZ` at the moment you write. Never estimate a timestamp. Reflect uses them to assign sessions to stages.

Keep `metrics` current:

- The "Engage." that starts the factory sets `engaged_at`.
- Ship sets `draft_prs_at`.
- Each unplanned stop adds one to `factory_stops`.
- Feedback adds one to `feedback_rounds`.
- QA sets `qa_first_pass` at the first tester report.

## Status block

`/engage status <KEY>` prints this and nothing else:

```
OT-964  Mark as complete and reopen          Story · 5 pts · epic OT-878 · track standard
✔ Setup  ✔ Planalysis  ● Implementation r2  ○ Verify  ○ Review  ○ Ship  ○ QA  ○ Feedback  ○ Reflect
Step:     Fix findings
Focus:    Fix F3 and F4 from round 1 review
Waiting:  worker ot964-fix (working, 6 min)
Open:     2 questions for product
Next:     Verify round 2 when the fixer reports
```

## Rules for every stage

- At each stage's entry, re-fetch the ticket and handle any change with `reference/change-requests.md`. On one past ticket the requirements moved after coding started, and nobody noticed for five days.
- Before you switch a branch in a repo, check every other ticket's `state.md` for `qa_hold: true`. If one holds, say so in one line and wait for the user. Testers may be using that checkout.
- Parallelize independent work across workers, within reason. `reference/workers.md` says when, and how many.
- Every worker brief includes `reference/standing-rules.md`, the org overlay files for its repos, and `plan.md`'s out-of-scope list.
- Record every user decision in `plan.md` under Decisions, with the date. A decision the user reaffirms is final.
- When a decision changes, update `plan.md` and `contract.md` and keep the previous version as `plan-v<n>.md` or `contract-v<n>.md`.
- Write to Jira, GitHub or Slack only on the user's explicit go. Planalysis's "Engage." is that go for pushes and draft PRs, and nothing more. Never mark a PR ready, request reviewers, post PR comments or replies, or edit Jira unless the user asks. Save replies, hand-offs and Jira text as drafts, each labeled a full replacement or a delta.
- Keep conclusions in your context and file dumps out of it. Workers write reports, and you read the reports.
