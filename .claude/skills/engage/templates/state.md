---
ticket: OT-000
title: null            # Jira summary
type: null             # Story | Task | Bug | Spike
kind: null             # a slug from reference/ticket-types.md
labels: []             # MoB, TechDebt, ...
epic: null             # epic key, or none
points: null
track: null            # quick | standard | project | answer
orchestrator: null     # this session's name from ListAgents, so a display can find the ticket a session runs
stage: planalysis      # a stage id from framework.json
step: "0"              # the current step id within the stage, from framework.json
stage_status: in_progress   # in_progress | waiting | awaiting_engage | complete
round: 0               # build loop round; 0 before the loop
feedback_round: 0      # feedback rounds handled after Ship
stages:
  setup: pending       # pending | in_progress | complete | skipped; complete only when dev-setup.md says so
  planalysis: in_progress
  implementation: pending
  verify: pending
  review: pending
  ship: pending
  qa: pending
  feedback: pending
  reflect: pending
waiting_on: nothing    # nothing | user | product | testers | worker:<name>
stop: null             # while the factory is stopped: the stop number from framework.json, else null
qa_hold: false         # true while testers use this workspace; no other ticket switches its branches
open_questions: 0      # questions for the user or product that are still open
prs: []                # PR links, filled by Ship
workers: []            # one entry per worker:
                       # - {name: ot964-be, tab: "w1:t4", stage: implementation, round: 1,
                       #    task: "Build the backend contract", status: working,
                       #    last_active: 2026-01-01T00:00:00Z, report: rounds/1/be.md}
                       # status: starting | working | idle | blocked | done | closed
metrics:               # Reflect reports these across tickets
  engaged_at: null     # UTC time of the "Engage." that started the factory
  draft_prs_at: null   # UTC time Ship opened the draft PRs
  factory_stops: 0     # unplanned stops for the user after "Engage."
  feedback_rounds: 0
  qa_first_pass: null  # pass | fail, from the first tester report
focus: One line on what is being worked out right now
updated: 2026-01-01T00:00:00Z
---

## Log

- 2026-01-01T00:00:00Z planalysis started
