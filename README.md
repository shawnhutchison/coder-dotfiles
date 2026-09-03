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

### Herdr's model
`session → workspace → tab → pane`. One workspace per project; the sidebar
(`Ctrl-Space b`) lists workspaces and every live agent with a status icon. The prefix is
**`Ctrl-Space`**. Full key reference is in the CHEATSHEET.

---

## Theming — Tokyo Night *Night*

The three surfaces that let you pick a variant (Ghostty, Neovim, Herdr) are pinned to
**Night** (background `#1a1b26`), not Storm (whose `#24283b` reads blue against a dark
terminal). Change
one, change the rest or they drift:

| Surface | File | How it's set |
|---|---|---|
| Ghostty | `local/ghostty/config` | explicit `background`/`palette` hexes |
| Neovim | `.config/nvim/init.lua` | `tokyonight` with `style = "night"` |
| Herdr | `.config/herdr/config.toml` | `[theme.custom]` pins every token |

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
2. **Herdr** — installs the pinned `HERDR_VERSION` release asset. It does *not* run
   `herdr update`: 0.8.2 deletes `session.json` on shutdown. See "Setup → On your Mac".
3. **Claude Code CLI** + config (`settings.json`, `CLAUDE.md`, `statusline.sh`).
4. **Claude Code output style** — symlinks `intuitive.md` into `~/.claude/output-styles/`
   and `jq`-merges `"outputStyle": "intuitive"` into `~/.claude/settings.json`. The merge
   matters: step 3 skips `settings.json` when the box already has one, so a plain copy
   would never activate the style on a re-provision. Caveat: picking a style from
   `/config` writes `outputStyle` to the *project* `.claude/settings.local.json`, which
   outranks `~/.claude/settings.json` — so in any ticket repo where that picker was used,
   this default loses silently. Delete the key from that repo to fall back to `intuitive`.
5. **Herdr ↔ Claude hook** — `herdr integration install claude`, so the sidebar shows each
   agent's live state and panes reattach to their conversation after a restart. Runs
   *after* the Claude config copy so it isn't clobbered.
6. **Language servers** — `typescript-language-server` into `~/.npm-global`, which the
   Claude Code LSP plugins declare but never install.
7. **Neovim config** + a headless `Lazy sync` so the first launch is instant.
8. **Herdr config** — copies `config.toml` only, never the directory (that would wipe
   `session.json` / scrollback), then reloads a running server.
9. **zsh / git** — sources this repo's `.zshrc`, sets zsh as the shell, adds git aliases.

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

The install trusts github.com's SSH host keys and installs `typescript-language-server`,
so the only manual step left is adding the Claude Code plugins — the marketplace is
private, so it needs your auth:
```sh
/plugin marketplace add RoadRunnerEngineering/rr-skills
/plugin install typescript-lsp@roadrunner-agent-skills
/plugin install ruby-lsp@roadrunner-agent-skills
/reload-plugins
```

### On your Mac
```sh
brew install herdr fzf jq neovim glow lazygit
brew install --cask font-jetbrains-mono-nerd-font   # Nerd Font for nvim icons
coder login && coder config-ssh
mkdir -p ~/.config/herdr
ln -sfn ~/dev/coder-dotfiles/.config/herdr/config.toml ~/.config/herdr/config.toml
ln -sfn ~/dev/coder-dotfiles/local/ghostty/config ~/.config/ghostty/config
echo 'source ~/dev/coder-dotfiles/local/mac.zsh' >> ~/.zshrc
exec zsh && dev-pin-herdr   # pin Herdr to 0.8.0, matching install.sh
```
Both Mac-side configs are symlinks into this repo rather than copies, so neither can
drift: edit the file here and the Mac has it. Only `config.toml` is linked, never the
`~/.config/herdr` directory — that also holds the client's own state.

`dev-pin-herdr` is not optional. Herdr 0.8.2 deletes the box's `session.json` on the
nightly Coder shutdown instead of saving it, so you reattach to one blank pane with
every Claude session gone. Both machines have to hold the same pin — `herdr --remote`
resyncs the box's binary to the client's version on attach, so pinning one side alone
is undone the next time you run `dev`. See CHEATSHEET §3, "Herdr is pinned to 0.8.0".

The local Herdr config is for the **theme** — the client paints the chrome, so
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
.claude/                      Claude Code: settings, CLAUDE.md, statusline, commands
.claude/output-styles/        `intuitive` output style — symlinked into ~/.claude/
.claude/skills/docs-pane/   renders a markdown examples file beside the chat, via glow
local/ghostty/config          Ghostty (Mac only) — symlinked into ~/.config/ghostty
local/mac.zsh                 `dev` / `dev-ls` / `dev-ssh` / `dev-version` / `dev-pin-herdr` (Mac only)
CHEATSHEET.md                 day-to-day keys and workflow
```

## Not in scope
- **Voice input** to a remote Claude Code: the mic is on the Mac and Claude runs on the
  remote box, so any speech-to-text must run locally on the Mac (macOS Dictation, or a
  local Whisper tool) and type into Ghostty.
