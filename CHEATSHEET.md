# Terminal Workflow Cheatsheet

Your VSCode replacement: **Ghostty** (terminal) + **tmux** (sessions/windows/panes) +
**Neovim** (editing & file navigation) + **Claude Code CLI** (the AI work).

Mental model:
- **tmux** = your window manager. Persistent sessions, split panes, survives disconnects.
- **nvim** = your editor + file browser.
- **Claude Code** = runs in its own pane; you drive it from the terminal.

---

## 0. The 60-second quickstart

```sh
tn work          # start a tmux session called "work"  (alias for: tmux new -s work)
nvim .           # open nvim in the current directory
# in nvim:  press Space then f then f  → fuzzy-find any file
#           press Space then e         → toggle the file tree sidebar
#           press Space then f then g  → search text across the whole project
```

To split your screen and run Claude Code beside your editor:
```
Ctrl-b  |        # split pane left/right  (Ctrl-b is the tmux "prefix")
claude           # start Claude Code in the new pane
Ctrl-h / Ctrl-l  # jump between panes (works into nvim splits too)
```

---

## 1. tmux — sessions, windows, panes

tmux keeps your work alive even if Ghostty closes or your connection drops.
Everything starts with the **prefix**: `Ctrl-b` (press it, release, then the next key).

### Sessions (whole workspaces)
| Command | Does |
|---|---|
| `tmux new -s work` (`tn work`) | new session named "work" |
| `tmux ls` (`tl`) | list sessions |
| `tmux attach -t work` (`ta work`) | re-attach to "work" |
| `Ctrl-b d` | **detach** (leaves it running in the background) |
| `tmux kill-session -t work` (`tk work`) | end a session |

The killer feature: detach (`Ctrl-b d`), close your laptop, reconnect later,
`ta work`, and everything — including a running Claude Code — is exactly as you left it.

### Windows (like browser tabs)
| Keys | Does |
|---|---|
| `Ctrl-b c` | new window |
| `Ctrl-b 1` … `9` | jump to window N |
| `Ctrl-b n` / `Ctrl-b p` | next / previous window |
| `Ctrl-b ,` | rename window |
| `Ctrl-b &` | close window |

### Panes (splits within a window)
| Keys | Does |
|---|---|
| `Ctrl-b \|` | split left/right |
| `Ctrl-b -` | split top/bottom |
| `Ctrl-h/j/k/l` | move between panes (no prefix — and it flows into nvim splits) |
| `Ctrl-b z` | zoom/unzoom the current pane (fullscreen toggle) |
| `Ctrl-b x` | close pane |
| drag a border with the mouse | resize |

### Scrolling & copy mode
- `Ctrl-b [` enters copy/scroll mode. Scroll with arrows/`Ctrl-u`/`Ctrl-d`, or just scroll with the mouse wheel.
- In copy mode: `v` start selection, `y` copy, `Esc` exit.
- Reload config after edits: `Ctrl-b r`.

---

## 2. Neovim — the essentials

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

---

## 3. Fuzzy finding & file navigation (the VSCode "Ctrl-P" feeling)

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

## 4. Going mouseless

- **Move between panes/splits:** `Ctrl-h/j/k/l` — one set of keys works across *both*
  nvim splits and tmux panes (that's the vim-tmux-navigator integration).
- **Open files:** `Space f f` instead of clicking the explorer.
- **Jump in a file:** `/word`, or `:42` for a line number.
- **Two files side by side:** open one, then `:vsplit`, then `Space f f` to load the other;
  hop with `Ctrl-h`/`Ctrl-l`.
- **Windows/tabs:** tmux windows (`Ctrl-b 1/2/3…`) instead of VSCode tabs.

You can keep the mouse — it works in both tmux and nvim. But every week, swap one
mouse habit for a keystroke and it compounds fast.

---

## 5. Claude Code in the terminal

You already know Claude Code from VSCode — it's the same tool, just driven from a pane.

```sh
claude                       # start an interactive session in the current directory
```

The recommended layout: a tmux window split into two panes —
**nvim on the left, `claude` on the right.** Edit/read on one side, prompt Claude on the other.

| In Claude Code | Does |
|---|---|
| type a prompt + `Enter` | ask / instruct |
| `Shift-Enter` | newline without sending |
| `/help` | list slash commands |
| `/install-my-plugins` | install your Roadrunner plugins (after `claude` auth) |
| `Esc` | interrupt Claude mid-response |
| `Ctrl-c` / `Ctrl-d` | quit |

Because it runs inside tmux, you can `Ctrl-b d` to detach and a long task keeps
running; re-attach later with `ta` to see the result.

---

## 6. First-run notes

- **Auth:** run `gh auth login` (GitHub) and `claude` (prompts on first launch).
- **Icons look like boxes?** The file-tree/statusline icons need a **Nerd Font**.
  In Ghostty, set one in your config, e.g. `font-family = "JetBrainsMono Nerd Font"`.
- **Change the nvim theme:** edit `~/.config/nvim/init.lua`, the `tokyonight` `style`
  (`storm`/`moon`/`night`/`day`), or swap the colorscheme entirely.
- **nvim plugins** are managed by lazy.nvim — run `:Lazy` inside nvim to see/update them.
