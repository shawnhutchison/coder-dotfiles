---
name: engage-reflect
description: Reflect stage of Engage: digest every Claude session that worked on a ticket, map the sessions to stages, find friction and missed chances, and write reflect.md with proposed changes to the framework for a later coder-dotfiles session. Use when the user asks to reflect on, review the process of, or run a retrospective on a ticket.
---

# Stage: Reflect

Reads every session that worked on the ticket, maps the sessions to the framework's stages, and looks for friction and missed chances. It ends with `reflect.md`, a list of proposed changes to this framework that the user applies in a later session on coder-dotfiles.

Reflect never edits the framework, the dotfiles repo or any memory. It only proposes.

## 1. Build the corpus

```
python3 -I ~/.claude/skills/engage-reflect/scripts/digest.py --ticket <KEY> \
  --out ~/.claude/tickets/<KEY>/reflect/corpus --exclude <your session id>
```

Your session id is the last directory of your scratchpad path. The script finds every session whose branch, working directory or prompts mention the key. It writes one condensed digest per session and an `INDEX.md` with sizes. Each digest shows:

- the human prompts, including messages typed mid-turn;
- the assistant text just before each prompt;
- agent spawns, skills, AskUserQuestion with its answers, herdr commands, files written and MCP calls.

Check `INDEX.md` for sessions that do not belong to this ticket, such as a workspace reused across tickets. Leave them out.

## 2. Map sessions to stages

Use the UTC timestamps in `state.md`'s log to assign each session, and each prompt in long sessions, to a stage and round. Sessions from before the framework existed have no log. Assign those by what they did.

## 3. Read the corpus

If the corpus is under about 150 KB, read it yourself. Otherwise split it by stage across workers (`~/.claude/skills/engage/reference/workers.md`, model sonnet, effort high). Each worker gets this file's step 4 as its brief, and writes `reflect/<stage>.md`.

## 4. Look for evidence

For each stage, find:

- **Corrections.** The user redirected scope, rejected output or corrected a claim. Quote them briefly with the session id.
- **Repeats.** An instruction the user gave more than once. It belongs in a stage file or in `~/.claude/skills/engage/reference/standing-rules.md`.
- **Addenda.** Rules added to a brief mid-run. Each one should move up front.
- **Late facts.** Something learned in a later stage that Planalysis could have found. Name the step that should have caught it.
- **Rework.** Reverts, extra rounds, discarded runs, re-recorded videos. Estimate the time lost.
- **Stalls.** Workers blocked on permission prompts, usage limits, stale servers, dead watches. Give the minutes lost.
- **Stage fit.** Steps that cost time and added nothing, and steps that were missing.
- **What worked.** Practices to keep, with evidence.
- **Drafts.** For draft stages, what the run shows the stage should say.
- **Dead text.** Rules and steps the run never needed, or that agents skipped with no harm. Propose cutting them. A stage file that only grows gets skimmed.

## 5. Write reflect.md

Write `~/.claude/tickets/<KEY>/reflect.md`:

1. **Summary.** Three to five sentences: how the ticket went, and the biggest single improvement.
2. **Timeline.** One row per stage and round: start, end, duration, sessions. Below it, the `metrics` from `state.md`: time from "Engage." to draft PRs, unplanned factory stops, feedback rounds. Compare them with earlier tickets' `reflect.md` files when they exist.
3. **Proposals.** One entry per proposed change, ranked by time it would have saved:
   - the target file, for example `engage-planalysis` step 5;
   - the exact text to add, change or remove;
   - the evidence: session id, a short quote, the cost;
   - a confidence of high, medium or low.
4. **Keep.** What worked, so a later edit does not remove it.
5. **Outside the framework.** Changes that belong elsewhere: other skills such as verify-ui, CLAUDE.md, memory, install.sh.

Write each proposal so a session that has never seen this ticket can apply it.

Before you propose a change, read the section it targets and `~/.claude/skills/engage/reference/rejected.md`. List a proposal that is already covered or already rejected under "Dropped", with the reason. For each Repeat, say whether a hook or a script could enforce the rule instead of more text.

## 6. Report

Post the top five proposals in chat, with the path to `reflect.md`. Mark Reflect complete in `state.md`.

## Across tickets

`/engage reflect all` runs the same steps on every ticket folder under `~/.claude/tickets/` that has a `state.md`. It writes `~/.claude/tickets/reflect-<date>.md` and favors patterns that repeat across tickets over one-off friction.
