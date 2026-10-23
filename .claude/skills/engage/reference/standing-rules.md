# Standing rules

Every worker brief includes this file. The orchestrator follows it too. Each rule comes from a correction the user made on a past ticket.

## Commands

- Never put `rm`, `rmdir`, `kill`, `killall`, `pkill`, `chmod`, `chown`, `sudo`, `docker` or `kubectl` in a command, not even as a harmless no-op. These are on the user's ask list. They stop an unattended worker on a permission prompt.
- Do not delete or overwrite files. Write a new, versioned name instead: `walk-2.cjs`, not an edited `walk.cjs`. List stray files in your report and leave them.
- Run scripts through their interpreter (`bash x.sh`, `node x.cjs`), so they need no executable bit.
- Give every script, wait and test run a timeout, so it ends on its own.

## Files

- Notes, reports, scripts and evidence go under `~/.claude/tickets/<KEY>/`. Never `/tmp`, which is cleared every night. Never inside a repo, unless the file is part of the change.
- Never write usernames, passwords, tokens or cookies into any file, log or report. Read them from the environment at run time, and mask any that appear in evidence as `***`.

## Git

- Workers do not commit, push, switch branches, stash or reset unless their brief says so.
- Commits for ticket work use `<KEY>: <3-4 lowercase words>`, grouped by file. Fewer commits are better.

## Outside the workspace

- No writes to Jira, GitHub or Slack.
- Dev ActiveStorage writes to the real staging S3 bucket. The Intacct push calls Intacct and Slack. Do not trigger either unless the brief says so.
- Workers do database reads only, through a Rails console in their own Herdr pane, driven with `herdr pane run` and `herdr pane read`. Do not build your own runner. Writes run in the orchestrator session. If you need one, stop and name it in your report.

## Code

- Follow the repo's dominant convention for each kind of change, not the nearest example.
- Put logic at the level it belongs. Never move code to satisfy a lint metric such as `Metrics/ClassLength`.
- A new file, export or shared constant needs two or more users and a name that says what it returns. Otherwise inline it. Prefer restoring the base branch's lines over adding a new shared piece.
- Domain content never goes into a generic component's file.
- No single-use hooks or helpers.
- Comments explain a non-obvious why, and name concrete things: the caller, the value, the failure avoided. Do not restate the code or narrate a past fix.

## Tests

- Add only tests that would catch a real regression. No tests that restate the implementation, check a mock against itself, or repeat a behavior at a second layer. CI takes about 30 minutes, and every test adds to it.
- A new test for a bug fails before the fix and passes after it.

## Scope

- Work only on the ticket's asks. Leave out scenarios the real client cannot reach.
- List out-of-scope problems in your report. Do not fix them.
- Items the plan marks out of scope stay out. Do not raise them again.

## Reports

- Lead with what needs the orchestrator's attention.
- Use `path:line` references.
- List the commands you ran and their results, with failures quoted.
- List deviations from the plan or the contract, and anything left undone.
- Label each claim as read from code or checked by running it.
