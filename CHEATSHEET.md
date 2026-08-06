# Terminal Workflow Cheatsheet

Your VSCode replacement: **Ghostty** (terminal) + **Herdr** (workspaces/tabs/panes) +
**Neovim** (editing & file navigation) + **Claude Code CLI** (the AI work).

Mental model:
- **Herdr** = your window manager. Persistent workspaces, split panes, survives
  disconnects *and* survives the Coder box shutting down overnight.
- **nvim** = your editor + file browser.
- **Claude Code** = runs in its own pane; Herdr tracks what it's doing.

The prefix is **`Ctrl-Space`**. Press and release it, then press the next key.
Lost? `Ctrl-Space` then `?` lists every active binding.

---

## 0. The 60-second quickstart

From your Mac, one command gets you into a Coder workspace:

```sh
dev              # pick a Coder workspace → lands you in its Herdr session
```

Already on the box (or working locally):

```sh
herdr            # start (or reattach to) your workspace — alias: h
nvim .           # open nvim in the current directory
# in nvim:  press Space then f then f  → fuzzy-find any file
#           press Space then e         → toggle the file tree sidebar
#           press Space then f then g  → search text across the whole project
```

Split your screen and run Claude Code beside your editor:
```
Ctrl-Space  v        # split right
claude               # start Claude Code in the new pane
Ctrl-Alt-h / -l      # jump between panes (no prefix needed)
```

Or skip the typing — `Ctrl-Space` then `Alt-c` opens Claude Code in a fresh pane directly.

---

## 1. Herdr — the model

Herdr nests one level deeper than tmux did:

```
session  →  workspace  →  tab  →  pane
```

- **Session** — the whole server-side world. Normally you only need the default one.
- **Workspace** — one per project. Has its own directory, git branch, and tab set.
  This is the level tmux didn't have, and it's the one worth using.
- **Tab** — like a browser tab within a workspace.
- **Pane** — a split within a tab. Where your shell, nvim, or Claude actually runs.

The **sidebar** (`Ctrl-Space b` to toggle) lists your workspaces and every running
agent, with a live status icon for each. That's the part that has no tmux equivalent.

### It's mouse-first
Unlike tmux, clicking is a first-class input. Click a pane to focus it, click a tab
to switch, drag a border to resize, drag to select text (it auto-copies), scroll with
the wheel. Keyboard and mouse are both fully supported — use whichever is faster.

---

## 2. Keys

### Panes
| Keys | Does |
|---|---|
| `Ctrl-Space v` / `Ctrl-Alt-v` | split right |
| `Ctrl-Space -` / `Ctrl-Alt-s` | split down |
| `Ctrl-Alt-h/j/k/l` | move between panes — **no prefix** |
| `Ctrl-Space h/j/k/l` | same, with the prefix |
| `Ctrl-Space z` / `Ctrl-Alt-z` | zoom/unzoom (fullscreen toggle) |
| `Ctrl-Space x` | close pane |
| `Ctrl-Space r` | resize mode (then arrows/hjkl, `Esc` to exit) |
| `Ctrl-Space ;` | jump to last pane |
| `Ctrl-Space Tab` | cycle panes |
| `Ctrl-Space Shift-P` | rename pane |
| `Ctrl-Space e` | open this pane's scrollback in `$EDITOR` |

### Tabs
| Keys | Does |
|---|---|
| `Ctrl-Space c` | new tab (created immediately, no name prompt) |
| `Ctrl-Space 1` … `9` | jump to tab N |
| `Ctrl-Alt-]` / `Ctrl-Alt-[` | next / previous tab — no prefix |
| `Ctrl-Space Shift-T` | rename tab |
| `Ctrl-Space Shift-X` | close tab |

### Workspaces — one per project
| Keys | Does |
|---|---|
| `Ctrl-Space w` | workspace picker (fuzzy) |
| `Ctrl-Space Shift-N` | new workspace (prompts for a name) |
| `Ctrl-Space Shift-1` … `9` | jump to workspace N |
| `Ctrl-Space Shift-←` / `Shift-→` | previous / next workspace |
| `Ctrl-Space Shift-W` | rename workspace |
| `Ctrl-Space Shift-D` | close workspace |
| `Ctrl-Space Shift-G` | new **git worktree** workspace |

That last one is worth knowing: Herdr creates a git worktree under
`~/.herdr/worktrees` and opens a workspace on it, so you can have two branches of
the same repo open side by side without stashing.

### Agents
| Keys | Does |
|---|---|
| `Ctrl-Space Alt-1` … `9` | jump straight to agent N |
| `Ctrl-Space Shift-J` / `Shift-K` | next / previous agent |
| `Ctrl-Space Alt-c` | Claude Code in a new pane |
| `Ctrl-Space o` | jump to whatever just notified you |

### Session & UI
| Keys | Does |
|---|---|
| `Ctrl-Space q` | **detach** (leaves everything running) |
| `Ctrl-Space ?` | show all active bindings |
| `Ctrl-Space b` / `Ctrl-Alt-b` | toggle sidebar |
| `Ctrl-Space g` | navigate mode — then `h/j/k/l` panes, `↑`/`↓` workspaces |
| `Ctrl-Space s` | settings UI |
| `Ctrl-Space Shift-R` | reload config after editing it |
| `Ctrl-Space Alt-g` | **lazygit** in a popup (stage, branch, diff, log) |
| `Ctrl-Space Alt-m` | browse markdown with **glow** in a popup |

### Scrolling & copy mode
- Mouse wheel just scrolls. Drag-select auto-copies.
- `Ctrl-Space [` enters copy mode: vim-style motions, `/` to search, `Esc` to exit.
  Output keeps streaming live while you're in it — it doesn't pause the process.

### Why not `Ctrl-h/j/k/l` for panes?
Those belong to Neovim, for moving between *splits*. Herdr has no
vim-tmux-navigator equivalent, so rather than fight over the same chord, pane
movement lives on `Ctrl-Alt-h/j/k/l`. One set of keys for nvim windows, another for
Herdr panes, no ambiguity about which one will react.

---

## 3. Coder workspaces — the `dev` command

`dev` lists your Coder workspaces and turns the one you pick into a Herdr session:

```sh
dev                    # fuzzy-pick a workspace, then attach
dev jade-capybara-52   # skip the picker
dev-ls                 # just list workspaces and their status
dev-ssh                # same picker, plain SSH shell instead of Herdr
```

A stopped workspace is started on connect, so you can pick one straight from the
list without starting it first.

### Which machine runs what

Herdr splits into a **client** (draws the UI, reads your keyboard) and a **server**
(owns the panes, the agents, the layout). `dev` runs the client on your Mac and the
server on the Coder workspace:

```
  Your Mac                          Coder workspace
  ┌──────────────────┐              ┌──────────────────────────┐
  │ Ghostty          │              │ herdr SERVER             │
  │ herdr CLIENT ────┼── ssh ──────▶│  ├ Claude Code panes     │
  │  (the UI)        │              │  ├ nvim panes            │
  └──────────────────┘              │  └ session.json          │
                                    └──────────────────────────┘
```

Your work — agents, panes, `session.json` — lives on the box that has the code, so
restart recovery (§4) is unaffected. What you gain by running the client locally:

- **Local clipboard.** Copying in Herdr lands in your Mac's clipboard, not the remote
  one. Image paste works too. Neovim yanks reach it as well — the config emits OSC 52
  on yank (see §7), so `yy` on the remote box is pasteable with `Cmd-V` on the Mac.
- **Local notifications.** A blocked agent raises a **macOS notification** via Ghostty,
  not just an in-app toast — the client rendering the toast is the one on your Mac.
- **Local keybindings.** Your `Ctrl-Space` prefix comes from your Mac's config.

Herdr installs itself on the host on first connect, and `install.sh` puts it there
too.

### Setting up your Mac
This repo is the payload Coder drops **into** a workspace, so the Mac half is kept
out of it — `dev` and friends live in `local/mac.zsh`, which `install.sh` never
copies. On your Mac:

```sh
brew install herdr fzf jq neovim glow lazygit
coder login && coder config-ssh

mkdir -p ~/.config/herdr
cp .config/herdr/config.toml ~/.config/herdr/config.toml   # local client reads this
ln -sfn ~/dev/coder-dotfiles/local/ghostty/config ~/.config/ghostty/config  # Ghostty theme + clipboard-write

echo 'source ~/dev/coder-dotfiles/local/mac.zsh' >> ~/.zshrc
```

See the README's **Setup → On your Mac** for the canonical version of this. The
Ghostty symlink is what sets `clipboard-write = allow`, which the yank→Mac-clipboard
path (§7) depends on — don't skip it.

That config copy matters: the local client reads the **local** config, so without it
your prefix is `ctrl+b` and the theme is Catppuccin.

Don't run the full `install.sh` on your Mac — it installs Claude Code, copies Claude
config, and wires the agent-state hook, none of which belong on a machine that isn't
running agents.

### Keep the two Herdr versions in step
Both machines have Herdr, doing different jobs — but they have to speak the same
protocol. When you attach, the client compares its protocol version to the remote
server's. **On a mismatch it replaces the remote binary and restarts the server,
which ends whatever was running there** — including sessions you wanted to keep.

Check before you assume a session is safe:
```sh
dev-version <workspace>    # prints local and remote versions side by side
```

If they've drifted, update deliberately rather than discovering it mid-attach:
```sh
brew upgrade herdr                      # local
ssh coder.<workspace> herdr update      # remote
```

This is why `install.sh` installs Herdr on the workspace even though `--remote` can
do it: provisioning it explicitly means the box starts at a known version, and the
direct `ssh` + `herdr` path works without ever attaching a local client.

### Not possible today
One Herdr client attaches to one server, and plugin v1 can't add sidebar entries or
custom pickers. So you can't see agents from two Coder workspaces in a single
sidebar — you switch between them with `dev` instead.

---

## 4. Surviving the nightly Coder shutdown

This is the reason we moved off tmux. Coder workspaces stop each night, which killed
the tmux server and took every session with it, because tmux only ever held that
state in memory.

Herdr writes its state to disk, in your home directory, which Coder persists:

| File | Holds |
|---|---|
| `~/.config/herdr/session.json` | workspaces, tab/pane layout, working directories |
| `~/.config/herdr/session-history.json` | pane scrollback |
| `~/.config/herdr/config.toml` | your config |

When the box comes back, the first `herdr` you run starts the server, which reads
those files and rebuilds your layout — same workspaces, same splits, same
directories, with scrollback intact. There's no daemon to babysit and nothing to
start at boot; it restores on first launch.

**Claude Code conversations come back too.** `resume_agents_on_restore = true` in the
config, plus the hook that `install.sh` installs via
`herdr integration install claude`, means an agent pane reattaches to its *original
conversation* rather than opening a blank prompt.

**This all rests on one assumption:** that your Coder workspace's `$HOME` is on a
persistent volume. Both the state files above and the dotfiles repo itself (Coder
clones it to `~/.config/coderv2/dotfiles`) live under `$HOME`. That's the standard
Coder template setup — but if a template ever gives you an ephemeral home, you lose
the sessions *and* the shell config together, and this section stops being true.

Two things worth knowing:
- `install.sh` deliberately copies only `config.toml` and never clears
  `~/.config/herdr/`, so re-running it won't throw away your sessions.
- `herdr session stop <name>` keeps state on disk; `herdr session delete <name>`
  discards it. Use `stop` unless you actually mean to start clean.

### Shell aliases
| Alias | Runs |
|---|---|
| `h` | `herdr` — start/reattach the default session |
| `hs <name>` | `herdr --session <name>` — start/reattach a named session |
| `hl` | `herdr session list` |
| `hstop <name>` | stop a session, keep its state |
| `hrm <name>` | delete a session **and** its state |
| `ha` | `herdr agent list` — what every agent is doing |
| `hcfg` | edit `~/.config/herdr/config.toml` |
| `hreload` | apply config changes to the running server |

Want to land in Herdr automatically on login? It's opt-in:
```sh
echo 'export HERDR_AUTOSTART=1' >> ~/.zshrc.local
```

---

## 5. Agent states — the actual reason for Herdr

Herdr knows what your agents are doing, and shows it in the sidebar:

| State | Meaning |
|---|---|
| `working` | busy, no input needed |
| `blocked` | **waiting on you** — a permission prompt or a question |
| `done` | finished its turn |
| `idle` | alive but nothing in flight |
| `unknown` | no integration reporting, or state not detectable |

`blocked` is the one that earns its keep: run Claude in three workspaces at once and
you don't have to poll them. The sidebar shows who needs you, a **macOS notification**
fires when a background agent finishes or gets stuck (delivery is set to `terminal`, so
the Herdr client on your Mac asks Ghostty to post it), and `Ctrl-Space o` jumps you
there. macOS must allow Ghostty to notify — System Settings → Notifications → Ghostty.
The agent panel is sorted by attention queue, so whoever needs you floats to the top.

From the shell, the same information is scriptable:
```sh
herdr agent list                          # every agent and its state
herdr agent read <target>                 # dump what a pane is showing
herdr agent prompt <target> "..." --wait  # send a prompt, block until it's done
herdr agent wait <target> --until blocked # wait for a specific state
```

---

## 6. Neovim — the essentials

nvim is **modal**. The big mental shift from VSCode: you're usually in **Normal mode**
(keys are commands), and you drop into **Insert mode** only to type text.

| Mode | Enter with | For |
|---|---|---|
| Normal | `Esc` | moving, commands (this is "home base") |
| Insert | `i` | typing text |
| Visual | `v` | selecting text |
| Command | `:` | running commands like `:w` |

**Golden rule:** lost or confused? Press `Esc` to get back to Normal mode.

### Save / quit
| Keys | Does |
|---|---|
| `:w` (or `Space w`) | save |
| `:q` (or `Space q`) | quit |
| `:wq` / `:x` | save & quit |
| `:q!` | quit, discard changes |

### Moving around (Normal mode — no arrow keys needed)
| Keys | Does |
|---|---|
| `h j k l` | left, down, up, right |
| `w` / `b` | next / previous word |
| `0` / `$` | start / end of line |
| `gg` / `G` | top / bottom of file |
| `{` / `}` | jump by paragraph/block |
| `Ctrl-u` / `Ctrl-d` | half page up / down |
| `42G` | jump to line 42 |
| `%` | jump to matching bracket |

### Editing
| Keys | Does |
|---|---|
| `i` / `a` | insert before / after cursor |
| `o` / `O` | open new line below / above |
| `x` | delete character |
| `dd` / `yy` / `p` | delete line / copy line / paste |
| `dw` / `cw` | delete / change a word |
| `u` / `Ctrl-r` | undo / redo |
| `.` | repeat last change |
| `gcc` | toggle comment on the line (`gc` in visual mode) |

The grammar clicks once you see it as **verb + motion**: `d` (delete) + `w` (word) = `dw`.
`c` (change) + `$` (to end of line) = `c$`. `y` (yank) + `}` (paragraph) = `y}`.

### Search within a file
| Keys | Does |
|---|---|
| `/text` then `Enter` | search forward |
| `n` / `N` | next / previous match |
| `*` | search the word under the cursor |
| `Esc` | clear the highlight |

### Windows within nvim
`Ctrl-h/j/k/l` moves between nvim splits. `:vsplit` / `:split` makes them.
(Herdr panes are `Ctrl-Alt-h/j/k/l` — see §2.)

---

## 7. Fuzzy finding & file navigation (the VSCode "Ctrl-P" feeling)

This is where you live. `Space` is the **leader** key — press and release it, then the next keys.

| Keys | Does | VSCode equivalent |
|---|---|---|
| `Space f f` | **find files** by fuzzy name | `Ctrl-P` |
| `Space f g` | **grep** — search text across the whole project | `Ctrl-Shift-F` |
| `Space f b` | switch between open buffers | open editors |
| `Space f r` | recently opened files | recent files |
| `Space /` | fuzzy search within the current file | `Ctrl-F` |
| `Space f h` | search the help docs | — |
| `Space e` | toggle the file-tree **sidebar** | Explorer |
| `Space o` | focus the sidebar | — |

Inside any fuzzy finder: type to filter, `Ctrl-j`/`Ctrl-k` (or arrows) to move,
`Enter` to open, `Ctrl-v` to open in a vertical split, `Esc` to cancel.

In the file-tree sidebar: `Enter` open, `a` add file/dir, `d` delete, `r` rename,
`H` toggle hidden files, `?` shows all the sidebar keybindings.

**Don't memorize all of this.** Press `Space` and **wait** — a popup (which-key)
lists every shortcut that starts with it. That's your discovery tool.

---

## 8. Claude Code in the terminal

Same tool you know from VSCode, driven from a pane.

```sh
claude                       # start an interactive session in the current directory
```

Recommended layout: a tab split into two panes — **nvim on the left, `claude` on the
right.** Edit/read on one side, prompt Claude on the other. `Ctrl-Space Alt-c` sets
up the Claude side in one keystroke.

| In Claude Code | Does |
|---|---|
| type a prompt + `Enter` | ask / instruct |
| `Shift-Enter` | newline without sending |
| `/help` | list slash commands |
| `Esc` | interrupt Claude mid-response |
| `Ctrl-c` / `Ctrl-d` | quit |

Because it runs inside Herdr you can `Ctrl-Space q` to detach and a long task keeps
running — and unlike tmux, it also survives the workspace restarting overnight.

---

## 9. Going mouseless

- **Panes:** `Ctrl-Alt-h/j/k/l`. **nvim splits:** `Ctrl-h/j/k/l`.
- **Open files:** `Space f f` instead of clicking the explorer.
- **Jump in a file:** `/word`, or `:42` for a line number.
- **Two files side by side:** open one, then `:vsplit`, then `Space f f` to load the
  other; hop with `Ctrl-h`/`Ctrl-l`.
- **Projects:** a Herdr workspace each (`Ctrl-Space w` to switch) instead of VSCode windows.
- **Tabs:** `Ctrl-Space 1/2/3…` instead of VSCode tabs.

Keep the mouse if you like — Herdr is genuinely mouse-first. But every week, swap one
mouse habit for a keystroke and it compounds fast.

---

## 10. First-run notes & troubleshooting

- **Auth:** run `gh auth login` (GitHub) and `claude` (prompts on first launch).
- **Icons look like boxes?** The file-tree/statusline icons need a **Nerd Font**.
  In Ghostty, set one in your config, e.g. `font-family = "JetBrainsMono Nerd Font"`.
- **Theming:** three surfaces are pinned to **Tokyo Night Night** (`#1a1b26`), the
  darkest variant. Change all three together or they drift apart:

  | Surface | File | Setting |
  |---|---|---|
  | nvim | `.config/nvim/init.lua` (workspace) | `style = "night"` |
  | Herdr UI | `~/.config/herdr/config.toml` (**your Mac** — the client paints it) | `[theme.custom]` |
  | Ghostty | `local/ghostty/config` (your Mac) | `background` + `palette` |

  Storm (`#24283b`) is the other common pick, but it reads visibly blue next to a
  dark terminal background. Only the background family differs between the two —
  every accent color is identical.
- **Icons still boxes?** No Nerd Font is installed. `brew install --cask
  font-jetbrains-mono-nerd-font`, then uncomment `font-family` in
  `local/ghostty/config`.
- **A keybinding does nothing?** Herdr disables invalid bindings rather than failing
  to start, and logs why. Check:
  ```sh
  grep -i 'invalid keybinding' ~/.config/herdr/herdr-server.log
  ```
  Note that unknown *config keys* are silently ignored, so check spelling against
  `herdr --default-config`, which prints the full annotated reference.
- **Agent shows `unknown`?** The integration hook is missing. Re-run:
  ```sh
  herdr integration install claude
  herdr integration status
  ```
- **Logs:** `~/.config/herdr/herdr.log`, `herdr-server.log`, `herdr-client.log`.
- **Diagnose a pane:** `herdr agent explain <target>` explains how Herdr detected
  (or failed to detect) the agent in it.
- **nvim plugins** are managed by lazy.nvim — run `:Lazy` inside nvim to see/update them.
  Note this is lazy.nvim the *plugin manager*, not the LazyVim *distro*.
- **No LSP in nvim, on purpose.** There's no go-to-definition, autocomplete, inline
  diagnostics or format-on-save here — nvim is a fast reader and navigator, and the
  code intelligence lives on the agent side instead. If you later want it for your own
  reading, add `nvim-lspconfig` + a completion engine to `init.lua`.
- **Update Herdr:** `herdr update` (or `brew upgrade herdr` on macOS).
