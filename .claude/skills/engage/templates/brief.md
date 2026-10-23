# <KEY> <role> brief

You are the <role> worker for <KEY>, "<Jira summary>". The orchestrator is the session named `<orchestrator name>`. It coordinates you and the other workers. Do not use AskUserQuestion. If a decision blocks you, write it in your report and finish.

## Read first

1. `~/.claude/skills/engage/reference/standing-rules.md`. Follow every rule.
2. `~/.claude/tickets/<KEY>/plan.md`. It wins over every other document.
3. <other files: contract.md, research reports, the findings to fix>

## Task

1. <numbered, concrete steps with `path:line` where known>

## Scope

- May write: <paths>. Everything else is read-only.
- Out (from `plan.md`, do not raise again):

## Done when

- [ ] <one checkable criterion per line>

## Verify before DONE

<exact lint, typecheck and spec commands for the touched paths>

## Timebox

<minutes>. When it runs out, send DONE with "partial" and say what is left.

## Output

Write `<report path>`. Follow the report rules in the standing rules.

## Finish

Send the orchestrator `DONE <report path>` with SendMessage, or `BLOCKED <one line>` if you cannot continue.

<For an Agent-tool worker, replace the line above with: End with the report path as your final message, or `BLOCKED <one line>` if you cannot continue.>
