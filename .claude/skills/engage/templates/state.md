---
ticket: OT-000
title: null            # Jira summary
type: null             # Story | Task | Bug | Spike
kind: null             # a slug from reference/engage-types.md
labels: []             # MoB, TechDebt, ...
epic: null             # epic key, or none
points: null
track: null            # quick | standard | project | answer
stage: planalysis      # setup | planalysis | implementation | verify | review | ship | feedback | reflect
stage_status: in_progress   # in_progress | waiting | awaiting_engage | complete
round: 0               # Implementation, Verify and Review round; 0 before the loop
feedback_round: 0      # PR review rounds handled by Feedback
stages:
  setup: pending       # pending | in_progress | complete | skipped; complete only when dev-setup.md says so
  planalysis: in_progress
  implementation: pending
  verify: pending
  review: pending
  ship: pending
  feedback: pending
  reflect: pending
prs: []                # PR links, filled by Ship
metrics:               # Reflect reports these across tickets
  engaged_at: null     # UTC time of the "Engage." that started the factory
  draft_prs_at: null   # UTC time Ship opened the draft PRs
  factory_stops: 0     # unplanned stops for the user after "Engage."
  feedback_rounds: 0
focus: One line on what is being worked out right now
waiting_on: nothing    # nothing | user | product | worker:<name>
open_questions: 0      # questions for the user or product that are still open
updated: 2026-01-01T00:00:00Z
---

## Workers

| Name | Tab | Stage | Round | Task | Status | Report |
|---|---|---|---|---|---|---|

## Log

- 2026-01-01T00:00:00Z planalysis started
