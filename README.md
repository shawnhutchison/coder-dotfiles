# coder-dotfiles

A terminal-first development environment for **remote [Coder](https://coder.com)
cloud workspaces**, driven as a thin client from a Mac. It replaces a VSCode-style
setup with **Ghostty + Herdr + Neovim + Claude Code**, and it is built to survive the
nightly shutdown that Coder workspaces go through.

If you just want the day-to-day keys and workflow, read **[CHEATSHEET.md](CHEATSHEET.md)**.
This file explains *how the whole thing is put together* and *why*.

---

## The big picture

There are two machines, and the repo has a half for each.

```
   YOUR MAC (thin client)                    CODER WORKSPACE (remote Linux)
 ┌───────────────────────────┐            ┌─────────────────────────────────┐
 │ Ghostty         terminal  │            │ Herdr server   panes/agents/tabs │
 │ Herdr client    the UI    │◀── SSH ───▶│ Neovim         editing           │
 │ local/ (mac.zsh, ghostty) │  coder.<ws>│ Claude Code    the AI work       │
 │ `dev` → attach a workspace│            │ rg fd fzf jq glow lazygit        │
 └───────────────────────────┘            │ session.json   restored on start │
                                          └─────────────────────────────────┘
```

- **`herdr --remote coder.<ws>`** (wrapped by the `dev` command) runs the *client* on
  the Mac and the *server* on the Coder box. Agents, panes, and layout live on the box
  that has the code; your clipboard, notifications, and the theme stay local. `dev` passes
  `--remote-keybindings server`, so **keys come from the box** — this repo's
  `.config/herdr/config.toml` is the single source of truth for them.
- Everything at the repo root and under `.config/` / `.claude/` is the **payload**
  Coder drops into a workspace. `install.sh` sets it up there.
- Everything under **`local/`** runs on the Mac only. `install.sh` never copies it.

### Why this shape
Coder workspaces stop every night. tmux held its state in memory, so a shutdown took
every session with it. Herdr persists workspaces, layout, and scrollback to disk under
`~/.config/herdr/` (which Coder keeps), and restores them when the server next starts —
so the box comes back overnight with the layout intact. That single property is the
reason the stack is Herdr rather than tmux.

---

## Components

| Piece | Role | Where it's configured |
|---|---|---|
| **Ghostty** | Terminal emulator (Mac) | `local/ghostty/config` |
| **Herdr** | Workspace/tab/pane manager, agent sidebar — the "window manager" | `.config/herdr/config.toml` |
| **Neovim** | Editor + file navigator | `.config/nvim/init.lua` |
| **Claude Code** | AI coding agent, one per pane | `.claude/` |
| **CLI tools** | `rg` `fd` `fzf` `jq` `glow` `lazygit` | installed by `install.sh` |
| **reviewr** | Herdr plugin: review an agent's diff, comment, send back | `.config/herdr/plugins/persiyanov.reviewr.toml` |

### Herdr's model
`session → workspace → tab → pane`. One workspace per project; the sidebar
(`Ctrl-Space b`) lists workspaces and every live agent with a status icon. The prefix is
**`Ctrl-Space`**. Full key reference is in the CHEATSHEET.

### The reviewr plugin
[`persiyanov/herdr-reviewr`](https://github.com/persiyanov/herdr-reviewr) is installed
automatically by `install.sh` (`herdr plugin install`, prebuilt binary — no Rust
toolchain). It opens a review pane beside an agent showing its diff, and lets you attach
line comments that go back to the agent's input. It requires Herdr ≥ 0.7.5, which the
in-place `herdr update` in `install.sh` guarantees. Its config is deliberately one line
(`theme = "tokyo-night"`): per the plugin's spec a single unknown key invalidates the
whole file and the pane then does nothing.

---

## Theming — Tokyo Night *Night*

The three surfaces that let you pick a variant (Ghostty, Neovim, Herdr) are pinned to
**Night** (background `#1a1b26`), not Storm (whose `#24283b` reads blue against a dark
terminal). The reviewr plugin shares the same palette *by name* — `tokyo-night` is its
only dark Tokyo variant, with no separate night/storm split — so it lines up too. Change
one, change the rest or they drift:

| Surface | File | How it's set |
|---|---|---|
| Ghostty | `local/ghostty/config` | explicit `background`/`palette` hexes |
| Neovim | `.config/nvim/init.lua` | `tokyonight` with `style = "night"` |
| Herdr | `.config/herdr/config.toml` | `[theme.custom]` pins every token |
| reviewr | `.config/herdr/plugins/persiyanov.reviewr.toml` | `theme = "tokyo-night"` (shared name) |

These files are the *source*. The Mac client reads its own local copies of the Ghostty
and Herdr configs — those copies are what actually render — so keep them in sync (the
Setup section symlinks/copies them).

The Neovim start screen (alpha-nvim) spells **BUILD SOMETHING** in a big figlet font,
each letter a different accent from the same palette (`#7aa2f7` blue, `#bb9af7` mauve,
`#9ece6a` green, `#e0af68` yellow, `#f7768e` red, `#73daca` teal, `#7dcfff` cyan,
`#ff9e64` peach).

---

## What `install.sh` does

Run on the Coder box (via Coder's dotfiles mechanism, or by hand). It is idempotent —
safe to re-run — and ordered deliberately:

1. **Core packages** — `zsh git curl jq ripgrep fd fzf neovim glow lazygit`. On Linux the
   ones apt lacks (nvim, fzf, glow, lazygit) come as release tarballs into `~/.local/bin`.
2. **Herdr** — install if missing, else `herdr update` in place (keeps the box current and
   clears reviewr's version gate).
3. **Claude Code CLI** + config (`settings.json`, `CLAUDE.md`, `statusline.sh`).
4. **Herdr ↔ Claude hook** — `herdr integration install claude`, so the sidebar shows each
   agent's live state and panes reattach to their conversation after a restart. Runs
   *after* the Claude config copy so it isn't clobbered.
5. **Herdr plugins** — install + theme reviewr.
6. **Neovim config** + a headless `Lazy sync` so the first launch is instant.
7. **Herdr config** — copies `config.toml` only, never the directory (that would wipe
   `session.json` / scrollback), then reloads a running server.
8. **zsh / git** — sources this repo's `.zshrc`, sets zsh as the shell, adds git aliases.

State it must never destroy: `~/.config/herdr/session.json` and `session-history.json`
(workspaces, layout, scrollback). The copy step touches only `config.toml`.

---

## Clipboard & notifications (the thin-client wiring)

- **Yank → Mac clipboard.** A headless Coder box has no clipboard provider, so Neovim
  emits **OSC 52** on yank; the escape rides through Herdr to Ghostty, which writes the
  Mac clipboard. Copy only — terminals block OSC 52 *reads*, so paste stays on Neovim's
  registers. Requires `clipboard-write = allow` in Ghostty (set here).
- **Blocked agent → macOS notification.** Herdr's toast `delivery = "terminal"` asks the
  outer terminal to post a desktop notification; since the Herdr client renders toasts on
  the Mac, that terminal is Ghostty. macOS must allow Ghostty to notify (System Settings →
  Notifications → Ghostty).

---

## Setup

### On the Coder workspace
Point Coder's dotfiles at this repo, or clone and run it:
```sh
git clone <this-repo> ~/dev/coder-dotfiles
~/dev/coder-dotfiles/install.sh
```
Then authenticate: `gh auth login`, and `claude` (prompts on first run).

### On your Mac
```sh
brew install herdr fzf jq neovim glow lazygit
brew install --cask font-jetbrains-mono-nerd-font   # Nerd Font for nvim icons
coder login && coder config-ssh
mkdir -p ~/.config/herdr
cp ~/dev/coder-dotfiles/.config/herdr/config.toml ~/.config/herdr/config.toml
ln -sfn ~/dev/coder-dotfiles/local/ghostty/config ~/.config/ghostty/config
echo 'source ~/dev/coder-dotfiles/local/mac.zsh' >> ~/.zshrc
```
The local Herdr config copy is for the **theme** — the client paints the chrome, so
without it the UI is wrong. It is *not* where your keys come from: `dev` attaches with
`--remote-keybindings server`, so `[keys]` and `[[keys.command]]` are read from the
workspace's own `config.toml`, the one `install.sh` writes. That's what makes a key you
add here — or a plugin action you bind after `herdr plugin install` — work on every new
workspace without touching the Mac. Apply a change with `hreload` (or `prefix+shift+r`);
no reattach needed.

Keep local and remote Herdr versions in step (`dev-version <ws>`); a mismatched client
replaces the remote binary on attach.

Then: `dev` (pick a workspace and attach) or `dev-ssh` (plain shell).

---

## File map

```
install.sh                    provisioning for the Coder box (idempotent)
.zshrc                        shell config, sourced into ~/.zshrc on the box
.config/nvim/init.lua         Neovim: theme, telescope, neo-tree, treesitter, dashboard
.config/herdr/config.toml     Herdr: theme, keys, sidebar, persistence
.config/herdr/plugins/        reviewr plugin config (copied to herdr's plugin config dir)
.claude/                      Claude Code: settings, CLAUDE.md, statusline, commands
local/ghostty/config          Ghostty (Mac only) — symlinked into ~/.config/ghostty
local/mac.zsh                 `dev` / `dev-ls` / `dev-ssh` / `dev-version` (Mac only)
CHEATSHEET.md                 day-to-day keys and workflow
```

## Not in scope
- **Voice input** to a remote Claude Code: the mic is on the Mac and Claude runs on the
  remote box, so any speech-to-text must run locally on the Mac (macOS Dictation, or a
  local Whisper tool) and type into Ghostty.
