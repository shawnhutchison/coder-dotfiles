---
name: engage-ship
description: Ship stage of Engage: group a ticket's changes into "<KEY>: 3-4 lowercase words" commits, push every branch, and open draft PRs with minimal bodies that follow each repo's PR template. Use when the engage skill reaches Ship, or when the user asks to commit, push and open PRs for a ticket.
---

# Stage: Ship

Turns the converged work into targeted commits, pushes every branch and opens draft PRs with minimal bodies. The PRs stay in draft for the user.

**Entry.** Review converged. The user's "Engage." at the end of Planalysis approved this stage: commit, push and open draft PRs. Do not ask again. Run this stage in the orchestrator session, not in a worker: auto mode judges a push against the user's words in the session that runs it. The code must be exactly the code that the last passing Verify saw. Compute each repo's tree id with the commands in `engage-review`, "Record the tree id", and compare it with the id in the last passing `rounds/<n>/verify.md`. If any id differs, go back to Verify.

**Feedback mode.** When `engage-feedback` invokes this stage, commit to the same branches and push. Do not open new PRs. Rewrite a PR body from the final diff only where what the PR does has changed. Skip steps 4 and 5 otherwise.

Set `stage: ship`, and `step` as each step starts. `<owner>/<repo>` below comes from `git -C ~/workspace/<repo> remote get-url origin`.

## 1. Check the ticket

Re-fetch the ticket and handle any change with `~/.claude/skills/engage/reference/change-requests.md`. A tweak or a gap goes back to Implementation as a round. New scope is recorded and does not block Ship. A reversal is factory stop 2.

## 2. Plan the commits

For each repo the ticket touched:

1. `git status --short` and `git diff --stat <base>`.
2. Leave out files that are not part of the ticket, such as local `db/structure.sql` noise, stray scripts and files under `~/.claude`. List them for the user. Never commit `.env` files or credentials.
3. Group the files into logical commits, whole files only. Do not split hunks. Fewer commits are better.
4. Name each commit `<KEY>: <3-4 lowercase words describing the change>`, for example `OT-964: guard route completion`. This format overrides any other commit-message guidance for ticket work.
5. Write the plan to `ship/commits.md`: per repo, each commit message with its files.

## 3. Commit and push

1. Commit each group with `git add <files>` and `git commit -m "<message>"`.
2. Check `git status`. Only the files listed as left out may remain.
3. Push every branch: `git push -u origin <branch>`.

## 4. Write the PR bodies

1. Find the repo's PR template. Look in `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/` and `docs/pull_request_template.md`.
2. Read three recent merged PRs by teammates to see how the team fills the template: `gh pr list --repo <owner>/<repo> --state merged --limit 3 --json number,title,body`.
3. Write `ship/pr-<repo>.md`. Keep every heading of the template, and fill each with the fewest words that state what the PR does now:
   - Current state only. No history of how the code got there.
   - Concrete and technical. Name the endpoint, the component, the state.
   - No general claims, no filler, no summary of the summary.
   - Link the Jira ticket. For a frontend and backend ticket, link the other PR.
   - For a stacked branch, name the base branch and why.
   - Under testing, say what was verified. Give the local path of any demo video, because `gh` cannot upload attachments.
   - Give the release facts from `plan.md`'s Release line under the template's notes heading: merge order, deploy order, run-once tasks. For a hold, start the title with `[DO NOT MERGE]` and say until when. A past PR merged against a hold written in its ticket and was reverted.
   - List the decisions the spec review recorded as "recommended, not confirmed", for reviewers to confirm.

## 5. Open the draft PRs

```
gh pr create --repo <owner>/<repo> --draft \
  --base <base> --head <branch> \
  --title "[<KEY>] <Jira summary>" \
  --body-file ~/.claude/tickets/<KEY>/ship/pr-<repo>.md
```

The base is the parent branch for a stacked ticket, and the repo's default branch otherwise. For a production hotfix, follow the Release line: it may need a PR to the production branch and a matching PR to the default branch.

## 6. Read back each PR

Run `gh pr view <number> --repo <owner>/<repo> --json url,title,isDraft,baseRefName,commits,files,body`, then check:

- it is a draft;
- the base is right;
- the commits and files match `ship/commits.md`. A wrong base shows up here as extra commits;
- no lockfile, dependency manifest, schema dump or generated file changed unless the plan names it;
- every claim in the body is in the diff;
- other open PRs that touch the same files, from `gh pr list --repo <owner>/<repo> --state open --limit 100 --json number,title,files`. Name each one in the report.

If the rendered body does not follow the template, fix it with `gh pr edit <number> --body-file <file>`. After both PRs of a frontend and backend ticket exist, add each one's link to the other's body.

Leave the PRs in draft. Do not request reviewers and do not mark them ready.

## 7. Record what shipped

Append to `ship/commits.md`, per repo: the PR number and link, the branch, the last pushed commit (`git rev-parse HEAD`), its tree id, and `git diff --stat origin/<base>...<branch>`, with the UTC time. Feedback rounds review only the diff since that commit, collect only comments newer than that time, and compare the stat after a merge.

## 8. Report

- The PR links, with commit counts per repo.
- **Decided without you.** Each decision dated after "Engage.", each product question built to its recommended answer, and each finding marked `reject` or `defer`. Riskiest first, one line each, with the reason and what reverting it would touch. This tells the user where to spend their PR review.
- **Not verified.** Each criterion that stayed inconclusive, and why.
- Files left uncommitted, and why.
- What the user must do by hand, such as attaching the demo video.

Mark Ship complete in `state.md`, set `waiting_on: user` and set `focus: Draft PRs open, waiting for PR review`. Tell the user that `/engage <KEY>` picks up their PR comments when they have reviewed, and that `/engage qa <KEY>` writes the QA hand-off when the ticket is ready for QA.

## Exit

Every branch is pushed, every PR is open as a draft, and `ship/commits.md` records the shipped commits.
