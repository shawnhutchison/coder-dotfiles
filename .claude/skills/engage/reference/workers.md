# Workers

A worker is a separate Claude session that does one bounded job from a brief file and reports back. The session that runs the ticket is the orchestrator. It owns every worker it starts: it watches them, answers for them, and closes them.

Workers run in auto mode, so they can act only on what auto mode allows without the user. Keep console writes, commits, pushes and anything else that needs the user's word in the orchestrator session (`SKILL.md`, "Auto mode").

## When to parallelize

Split work across workers when it is independent, within reason:

- No worker needs another worker's output while it runs.
- Each piece is worth at least ten minutes of work, or would otherwise pull many files into the orchestrator's context.
- No more than four workers run at once. The workspace has limited memory: a watch died under memory pressure on OT-916.
- Only one worker at a time runs a database test suite, or a recorded browser flow against one app. Concurrent rspec runs deadlocked on the shared test DB on OT-945.
- The quick track uses no workers.

Typical splits: one researcher per repo in Planalysis, backend and frontend implementers in Implementation, one reviewer per repo in Review.

## Herdr or the Agent tool

- With `HERDR_ENV=1`, start workers in Herdr tabs so the user can watch them.
- Without Herdr, use the Agent tool with `run_in_background: true` and the same brief file. Its completion notification replaces the callback.

## Start a worker in Herdr

Name each worker `<key>-<role>` in lowercase, for example `ot964-be`. Agent names must match `[a-z][a-z0-9_-]{0,31}`. Use the same name for the tab label.

```
p=$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd ~/workspace/coyote \
      --label ot964-be --no-focus | jq -r .result.root_pane.pane_id)
herdr agent start ot964-be --kind claude --pane "$p" --timeout 60000 -- \
  --model opus --effort high --permission-mode auto -n ot964-be
herdr agent prompt ot964-be "Read ~/.claude/tickets/OT-964/briefs/be.md and do what it says."
```

In zsh an unquoted `$var` does not split on spaces, so a loop over a string of names starts nothing. Write a small function with named arguments, and call it once per worker.

## Model and effort

These are starting defaults. Reflect proposes changes when a run shows a better choice.

| Work | Model | Effort |
|---|---|---|
| Repo research in Planalysis | opus | high |
| Epic, ticket and PR-history sweep | sonnet | medium |
| Design extraction from exports, PDFs and screenshots | opus | high |
| Implementer | opus | high |
| Verifier | opus | high |
| Fixer with a precise list | opus | medium |
| Style pass and code review | opus | medium |
| Reflect corpus reader | sonnet | high |

On OT-945 the user moved reviewers and fixers to medium effort because high was too slow.

## Briefs

Write each brief to `~/.claude/tickets/<KEY>/briefs/<role>.md` from `templates/brief.md`. A brief that exists only in `/tmp` or a scratchpad is lost on the next restart. A brief in a file also makes a replacement worker cheap.

- Start no worker whose brief has an empty field. "May write", "Done when" and "Verify before DONE" give a worker a boundary and a finish line it can check itself.
- Paste the path and the conclusions of any report the worker depends on.
- When a worker dies from memory or context, restart it from the brief with a smaller task. After a tool error, restart it as is. After two failures on the same task, replan the task.

## Report back

Every brief ends with the callback: SendMessage to the orchestrator with `DONE <report path>`, or `BLOCKED <one line>`. Before you write the first brief, run ListAgents in the orchestrator session. Its row for this session gives the name to put in the brief. Session names change after a Coder restart, so update the brief when that happens. An Agent-tool worker has no callback to send: it ends with the report path as its final message, and its completion notification reaches you.

Also arm a background watch for each worker, with `run_in_background: true`:

```
herdr agent wait ot964-be --until blocked --until idle --until done --timeout 3600000
```

- If a watch dies, re-arm it. The user should never have to ask for status.
- `blocked` is an event. Read the screen with `herdr agent read <name> --source visible --lines 40`, then tell the user what is waiting for approval and in which tab.
- Never answer a permission prompt for the user, and never relay an approval: auto mode does not count approval passed on by another agent. Console writes run in the orchestrator session (`SKILL.md`, "Auto mode").
- Update the worker's entry in `state.md`'s `workers` list when it starts, reports, goes idle or closes. Set `last_active` each time from `date -u +%FT%TZ`.

## Correct a running worker

1. Stop it first: `herdr agent send-keys <name> esc`.
2. Send the change: `herdr agent prompt <name> "Coordinator: <change>"`.
3. Append the change to the brief file as a dated addendum, so a replacement worker gets it too.

## Close and reuse

- Close the tabs you created when a worker's step is done: `herdr tab close <tab id>`. Never close tabs you did not create.
- Reuse a worker only while its prompt cache is warm. Before you prompt an existing worker, or SendMessage to one, compute its idle time from `last_active` in `state.md`. Under 55 minutes, reuse it. Otherwise, or when `last_active` is empty, close it and start a new worker from its brief. Log the choice with both times. The margin under the hour covers the time the prompt takes to arrive.

## Your own context

`state.md`, `plan.md` and `findings.md` must be enough for a new session to resume with `/engage <KEY>`. Bring them up to date before your context grows past about 300k tokens, then suggest that the user resume in a new session.
