# Change requests

A change request is a new or changed ask that arrives after Planalysis read the ticket. It can come from a Jira comment, a description edit, a new attachment, a PR comment, a tester's report or a note the user relays. Every stage handles changes with this file.

On past tickets, a third of all tickets changed at QA or acceptance. Developers absorbed small changes in files they had already touched, and split larger ones into new tickets. Requesters usually left that call to the developer. This file makes the same call without stopping the factory.

## Detect

- Re-fetch the ticket at each stage entry and compare it with `ticket-snapshot.md`. Compare the description line by line: struck-through text is a change.
- Read every comment and attachment newer than the snapshot. A new screenshot is a change until you have read it.
- A status moved back from QA or acceptance is a change.

## Classify

| Class | What it looks like | Handling |
|---|---|---|
| defect | A criterion fails | A `fix` finding |
| environment | The workspace, the data, a flag or a blocked external call misled the tester | Fix the environment and draft an answer. No code finding |
| question | Someone asks how something works | Draft an answer |
| tweak | Copy, a label, a default sort or filter, how an empty or zero value shows, an error message | Absorb it |
| gap | Behavior the ticket left unsaid, for a state its own feature owns | Absorb it in repos that already have this ticket's PRs, when it needs no new endpoint or migration. Otherwise treat it as new scope |
| new scope | Needs another repo, an endpoint, a migration or a new screen, or belongs to another ticket | Route it to the ticket that owns it, or draft a new ticket |
| reversal | Undoes a decision in `plan.md` or a behavior already shipped | Stop for the user |

When a change fits two classes, take the larger one. When the requester offers "here or in a separate ticket", decide with this table and give the reason.

## Record and draft

- Add each absorbed tweak and gap to `plan.md` Asks with its source, date and the requester's role, and give it a criterion.
- Add new scope to Out of scope with its owner ticket. Record each change's class and reason under Decisions.
- Save drafts in `feedback/replies-<k>.md`. Post nothing. A new ticket draft holds the ask in the requester's words, its criteria, the parent and the repos.
- When a change touches behavior that QA already passed, write `qa/delta-<k>.md`: what changed, the criteria to retest, and any new seed or flag steps. On past tickets, changes made after QA passed reached production untested.
- When the round has its verdicts, update `ticket-snapshot.md`.

## When it runs

- Before "Engage.": Planalysis folds the change into the plan.
- Inside the factory: absorbed changes join the current round.
- After Ship: Feedback runs them as a feedback round.
