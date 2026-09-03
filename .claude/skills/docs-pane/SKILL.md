---
name: docs-pane
description: "Open a side pane in Herdr that renders a growing markdown file of worked code examples with glow, so a prose explanation can point at them. Use during deep-dive sessions — walking through a PR, explaining how a subsystem works, teaching a codebase — whenever the explanation needs code examples that would bury the prose if inlined. Also use when the user asks to render or preview a markdown file in a Herdr pane. Requires HERDR_ENV=1."
---

# Docs pane

`docs-pane <file.md>` renders a markdown file with `glow` in a companion Herdr
pane named `docs`, then leaves that pane at its shell prompt. It reuses the same
pane for every render in a workspace, so call it as often as you like.

```bash
docs-pane /tmp/pr-review-examples.md
```

The script refuses to run outside Herdr, splits right from the calling pane the
first time, and never takes focus.

## The explanation workflow

This exists so the main thread can stay prose. Code examples live in the pane.

1. At the start of the session, write an examples file under the scratchpad
   directory and render it once.
2. As the explanation advances, **append** to that same file and re-render. One
   growing document, one pane — the user keeps scrollback over the whole session.
   Do not write a file per example.
3. Number every section: `## Example 3 — Retry backoff in worker.rb:88`.
4. In the main thread, refer to it by number: "The retry path wraps the whole
   batch, not the single call — see example 3 in the docs pane."

Keep the prose complete on its own. A reader who never looks at the pane should
still follow the argument; the examples reinforce it, they do not carry it.

## Example file shape

```markdown
# Worker retry — walkthrough

## Example 1 — The call site (app/jobs/sync_job.rb:41)

​```ruby
retry_with_backoff { batch.each(&:sync!) }
​```

The block wraps the loop, so one failure replays every item.
```

Prefer short excerpts with a `path:line` heading over full file dumps. The user
can open the file; they cannot un-read a 200-line paste.

## Notes

- `glow` renders and exits. Do not switch the script to `glow -p`: the pager
  holds the pane, and the next render types into the pager instead of the shell.
- If a render looks wrapped wrong, the pane was resized. Re-run the command.
- The pane ID is cached in `$TMPDIR/docs-pane-$HERDR_WORKSPACE_ID`. Delete that
  file to force a fresh split.
