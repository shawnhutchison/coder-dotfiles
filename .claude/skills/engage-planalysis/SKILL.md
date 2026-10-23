---
name: engage-planalysis
description: Planalysis stage of Engage: research a Jira ticket from near-zero knowledge (ticket, epic, related tickets, designs, code), interview the user until the ask is clear, analyze the repos, and produce plan.md with the files likely to change. Ends when the user says "Engage.". Use when starting to analyze, research or plan a ticket, or when the user asks to understand what a ticket asks for.
---

# Stage: Planalysis

The user starts from close to zero knowledge of the ticket. Planalysis ends when the user and you share an understanding of the whole problem and the user approves a plan that names the files likely to change. The user approves with "Engage."

This is the stage where the user learns the problem and weighs the options. Show them the options and the evidence behind each. Do not hand them only a conclusion.

It is also the last planned contact with the user before the draft PRs. After "Engage." the factory runs on its own. Anything the build, Verify, Review or Ship would have to ask must be settled here.

**Who runs it.** The session the user started the ticket in runs Planalysis itself, because the interview is the core of the stage. Send repo scans and wide sweeps to workers (`~/.claude/skills/engage/reference/workers.md`) and keep only their conclusions.

**Read-only.** Do not edit repos, switch branches or write to Jira, GitHub or Slack. `git fetch` and database reads are allowed. The only files you write are under `~/.claude/tickets/`.

**Output.** `plan.md` from `~/.claude/skills/engage/templates/plan.md`, plus a chat summary of 300 words or fewer.

## 0. Open the ticket

1. Read `~/.claude/tickets/dev-setup.md`. If it is missing or `partial`, say so in one line and offer `/engage setup`. Continue either way.
2. If `~/.claude/tickets/<KEY>/state.md` exists, resume. Read `state.md` and `plan.md`, tell the user in three lines where things stand, and continue from `focus`.
3. Otherwise create the folder, `state.md` from `~/.claude/skills/engage/templates/state.md` and `plan.md` from `~/.claude/skills/engage/templates/plan.md`. In `state.md`, set `stage: planalysis`, leave the fields you do not know yet as `null` until step 2, and set `stages.setup` to `complete` only if the Setup marker says so.
4. `plan.md` grows as you go: fill each section when the step that owns it ends. Step 10 finishes it.
5. If the user's first message carries context, write every claim, constraint and preference in it into `plan.md` under "User context" before you do anything else. Kickoff messages often hold a dozen decisions.

## 1. Collect sources before asking anything

The user should not have to tell you which sources exist. Gather these, and record in `plan.md` under Sources what each one said. On the quick track, collect them yourself. On the standard and project tracks, send the epic and PR-history sweep to one worker (`~/.claude/skills/engage/reference/workers.md`) and read the ticket yourself.

- **Jira access.** Get the Atlassian `cloudId` once with `getAccessibleAtlassianResources`, and reuse it.
- **The ticket.** `getJiraIssue` with summary, description, comment, status, issuetype, labels, priority, parent, issuelinks, subtasks, attachment and `customfield_10026` (Story Points), in markdown. `customfield_10016` is empty in this Jira. Read every comment. The latest decision wins. Save the description and comments to `<KEY>/engage-snapshot.md` with the ticket's `updated` time.
- **The epic.** `searchJiraIssuesUsingJql` with `parent = <EPIC> ORDER BY key`, all statuses, with summary, status, labels and `customfield_10026`. Leave `assignee` out: its avatar payload is most of the response. Fetch owners only for the few related tickets in step 3.
- **Sibling epics.** For a project with several epics, find the sibling epics by their shared name prefix. Then search their children for the ticket's key terms: `parent in (<epics>) AND text ~ "<term>"`. On OT-974 this found a dependency the ticket did not link.
- **Mentions elsewhere.** `text ~ "<KEY>"` finds comments on other tickets that mention this one. Asks for this ticket have turned up in a sibling's comment thread.
- **Linked tickets in other projects**, with any flags they depend on.
- **Product docs.** A Confluence PRD linked from the epic or the ticket.
- **Design sources.** Claude artifacts, design export zips, PDFs, Figma links and screenshots. Record each one's date and author.
- **Code state.** The repos under `~/workspace` (`~/.claude/skills/engage/reference/repos.md`). The checkouts often hold another ticket's branch, so never read code from the working tree. Run `git -C <repo> fetch origin`, read from `origin/<base>` with `git show` and `git grep`, and cite `path:line` from that ref. Find in-flight work with `git -C <repo> branch -r | grep -i <KEY>` and `gh pr list --repo RoadRunnerEngineering/<repo> --search "<KEY> in:title" --state all`, for this ticket and each dependency. Without `in:title` the search returns other keys.
- **Data and runtime.**
  - The dev DB: open a Rails console in a Herdr pane of your own tab (`herdr pane split --current --direction down --no-focus`, then `herdr pane run <pane> "cd ~/workspace/coyote && bundle exec rails console"`). Wrap reads in `ActiveRecord::Base.while_preventing_writes { ... }`.
  - The staging console, for production-like data: ask the user how they reach it the first time, and add the method to `~/.claude/skills/engage/reference/repos.md` in a later dotfiles session.
  - Datadog, for errors and deploy events.
  - A bug's reproduction comes from these sources. Record what you checked and what you could not.
- **Constraints.** MCP access goes through mintmcp. The Coder apps use username and password login, not SSO. The dotfiles repo is public. Note any feature flags.

## 2. Classify and pick a track

- **Type**: Story, Task, Bug or Spike.
- **Label**: MoB means users reported it, and the work is usually self-contained. TechDebt is usually self-contained too. No label means project work, so the epic name places it.
- **Surface**: frontend, backend, both, devops, data, or none for a question, an estimate or a review.
- **Kind**: one row of `~/.claude/skills/engage/reference/engage-types.md`, written as its slug. The kind sets the deliverable and which writes are allowed.
- **Track**:

| Track | When | Planalysis depth |
|---|---|---|
| quick | One repo, one concern, no contract, no design | Scan the code yourself, no workers. `plan.md` fills Verdict, Asks, Decisions, Files likely to change, Verification recipe, The factory will stop for, and Build plan. Other sections get one line or "n/a". |
| standard | One or two repos, a contract or a design | One worker per repo, plus a design worker when a design exists. |
| project | Depends on in-flight tickets, or spans three or more repos | Every step in full, with a dependency table and a branch-stack plan. |
| answer | Spike, triage, estimate, question, or review of someone else's PR | The deliverable is a written answer. "Engage." means produce it. Implementation, Verify and Review do not apply. |

State the type, kind and track in one line, and fill them into `state.md`. The user can change them.

## 3. Place the ticket

- Build a table of related tickets: ticket, status, owner, relation (dependency, sibling, follow-up) and branch or PR state (merged, in review, not started). A dependency that merged yesterday changes the plan.
- Before you call a capability missing, check the in-flight dependencies. It may sit on an unmerged branch.
- Give every adjacent concern an owner ticket. Move an item out of scope only when another ticket owns it or the user agrees. An unresolved direct ask is an open question, not out of scope.
- Design for the known next tickets. Avoid a temporary fix that a later ticket would have to undo.

## 4. Restate the ask

- Number every ask in a table: the ask in the ticket's words, where it came from (description, comment or a sibling's comment), its state today, and the change.
- Read each section of the ticket for what it is:
  - Asks, technical notes and answered refinement questions are asks or constraints.
  - A Cause or Current-vs-expected section is a claim. Check it against the code.
  - Context is background.
- List every shipped behavior or stored value the ticket changes. Each one needs product sign-off. Where stored values change, it also needs a migration story. This list is where reverts start: on OT-964 a reversed payout rule was built, verified, polished and reviewed before product dropped it.
- For a ticket that is still pre-refinement, write its asks as questions. Do not invent requirements.

## 5. Interview until the understanding is shared

Ask with AskUserQuestion. Ask only questions whose answers change the work. Ask up to four at a time, put the recommended option first, and give each option one line of reasoning. Batch the questions, and do not ask what a source in step 1 already answers.

Settle these whenever they apply:

- **Design authority.** Which source is binding and which is only a reference? Is the design current and agreed by the designer for this ticket? Which design-system defaults does the user override? On OT-916 an unsettled design meant about 60 live change requests and two reversals.
- **Precedence.** When the design conflicts with the backend or the ticket, both frontend and backend follow the backend contract and the ticket. List each conflict for product. Do not block on it.
- **Operating profile.** These go to reviewers as review inputs:
  - how many people use the feature at once;
  - how the real client builds its requests;
  - which endpoints are in scope;
  - whether production and staging hold data for this feature (greenfield means no backfill);
  - which inherited code is out of scope.
- **Side effects.** List what dev or test actions touch outside the workspace. Dev ActiveStorage writes to the real staging S3 bucket. The Intacct push calls Intacct and Slack. Note whether the dev DB is shared with QA.
- **Terms.** Write a glossary for any word the frontend and backend use differently. For example, a coyote "stop" is one tech task, but a lyra "stop" is a location.
- **Contract sign-off.** When the tech lead or a sibling ticket has a say in the API, get it before code.
- **Branches.** Branch from staging, or stack on an in-flight branch? Decide the PR base, how to merge the parent forward, and which failures are inherited. Tilt serves every app from `~/workspace/<repo>`, so the build must happen in that checkout. Verify cannot see a worktree. If that checkout holds another ticket's uncommitted work, ask the user how to set it aside.

Questions only product can answer go in `plan.md` under "Questions for product", each with a recommended answer. Build to the recommended answer and keep the rule easy to change. Offer to draft a Jira comment. Post it only on the user's go.

Questions for the user that are still open go in `plan.md` under "Open questions for the user". An answer the user has not confirmed goes in Decisions marked "recommended, not confirmed".

Test the user's framing against the evidence, and say so when it does not hold. Stop interviewing when no open question would change the plan.

## 6. Technical analysis

Spawn the research workers for the track (`~/.claude/skills/engage/reference/workers.md`). Briefs come from `~/.claude/skills/engage/templates/brief.md`, and reports go to `research/<name>.md`. Each repo worker reports:

1. **Code to reuse**: piece, `path:line`, and how this ticket uses it.
2. **The dominant convention** for each kind of change the ticket makes, with a repo-wide usage count. Kinds include forms, data fetching, mutations, formatters, toasts, state machines and specs. The nearest similar file is not the convention: on OT-916 a plan copied a hand-rolled form while 313 lyra files used react-hook-form.
3. **Similar past work**: PRs and commits that did something like this (`gh pr list --search`, `git log -S`), with what they did.
4. **Consumers** of anything the ticket changes: payload builders, client auth, calling views.
5. **Files likely to change**, each with the change and the reason.
6. **Risks**: ordering, locking, migrations, flags, external calls.
7. **Open questions.**

Workers label each claim as read from code or checked by running it. Where a check is cheap, they run it: a console read, a request or an EXPLAIN.

Merge the reports yourself. Where two reports disagree, read the code and decide.

For a frontend and backend ticket, draft `contract.md`. The backend owns it, and it covers endpoints, request and response shapes, errors and states. For a frontend-only ticket, name the existing API and confirm its shapes from a real response.

Agree on the tests before any are written. Fill `plan.md`'s Tests table: each seam to test, the regression it catches, the existing spec to follow, and whether the spec is new or changed. Review treats a test outside the table as a finding, unless a fix needed it. Every test adds to a 30-minute CI run.

The analysis usually raises new questions, and on OT-974 it raised the most important one. Ask them now, the same way as step 5, before you write the recipe.

## 7. Write the verification recipe

Verify starts from this recipe. Without one, verifiers on past tickets fell back to API shortcuts and false claims that the UI could not do a step.

- Number the acceptance criteria. For each, write how to prove it: a UI path, an API call or a DB state.
- For a bug, the first row is the reproduction: the reporter's example, the correct and the broken end states, and one command or UI path that has shown the broken state twice. List three to five hypotheses for the cause, each with the observation that would rule it out.
- For each state the criteria need, list the records required and how to create them: through the UI, the console or a seed script. Reuse `~/.claude/tickets/recipes/<area>.md` when it exists. When it does not, write it from what this step found, so Verify and QA start from it.
- List the console writes that setting up the data needs. Step 9 gets them approved.
- List the Tilt resources and URLs, and any known-good test harness to reuse.
- List the external calls to avoid or stub.
- For QA: what testers need, such as seed data, users, flags and tools.

## 8. Size the work and plan the build

- Estimate points against sibling tickets. If the estimate differs from the ticket's points, say why.
- Plan the build: branches and bases, worker roles, what runs in parallel, and the order.

## 9. Make the factory ready

Walk through the build plan and the recipe, and find every point where the factory would have to stop for the user (`~/.claude/skills/engage/SKILL.md`, "When the factory stops for the user"). Settle each one now:

- **Console writes.** Show the user the list from step 7 and ask them to approve it in this session, in their own words. Auto mode accepts approval only from the user in the session that runs the command. A worker's session never has it, so the orchestrator seeds the data from this session during Verify. Record the approval in `plan.md` under Decisions.
- **Decisions the build will meet.** Each has a decision in `plan.md` or a recommended answer the factory may build to.
- **Design.** The binding source is named, so Verify can compare against it without asking.
- **Design pass.** For a ticket with UI changes, ask whether to schedule a design pass after the round 1 build. Recommend yes, unless the design is final and agreed by the designer. Record the answer as `Design pass: yes` or `no` in `plan.md`'s build plan.
- **Branches and PRs.** Bases, PR bases and the PR title come from the plan.
- **Environment.** The Tilt resources the build and Verify need are up (`/usr/local/bin/tilt get uiresources`).

Write the points you could not settle into `plan.md` under "The factory will stop for". Keep that list short.

## 10. Report and wait for "Engage."

1. Finish `plan.md`: fill the Verdict, and check that every section the track needs is filled.
2. Post the chat summary, 300 words or fewer. Cover:
   - what we will build and why, and the hard parts;
   - the decisions and the open questions;
   - a "Files likely to change" table of at most 15 rows (the full table stays in `plan.md`);
   - what the factory will stop for, if anything.

   End with one line: "Engage." starts the build and ends with draft PRs for you to review on GitHub.
3. Set `stage_status: awaiting_engage`, and set `focus` to what the user is reviewing.
4. Fold the user's feedback into `plan.md`, and repeat until they say "Engage."

## Exit

- Every ask maps to a change, or to a named owner ticket.
- No open question would change the plan. Product questions may stay open with their recommended answers.
- `plan.md` has the "Files likely to change" table and the verification recipe.
- The console writes are approved in this session, and every other factory stop is settled or listed.
- `ticket-snapshot.md` exists.
- The user said "Engage."
