# ============================================================================
# LOCAL MACHINE ONLY — not installed into the Coder workspace.
#
# Everything else in this repo is the payload Coder drops into a workspace.
# This file is the other half: commands you run on your own machine to reach
# those workspaces. install.sh deliberately never copies it.
#
# Source it from your own shell config:
#   echo 'source ~/dev/coder-dotfiles/local/mac.zsh' >> ~/.zshrc
#
# Prerequisites (macOS):
#   brew install herdr fzf jq
#   coder login && coder config-ssh
#   mkdir -p ~/.config/herdr
#   cp ~/dev/coder-dotfiles/.config/herdr/config.toml ~/.config/herdr/config.toml
#
# That last copy is for the *theme* only — the client paints the chrome, so
# without it the UI is Catppuccin. Keybindings do NOT come from it: `dev`
# attaches with --remote-keybindings server, so the box's config.toml owns
# every key. See the comment on dev() below.
# ============================================================================

# --- Coder workspaces + Herdr remote attach ---------------------------------
# Herdr splits into a client (the UI) and a server (the panes, agents, layout).
# `herdr --remote <host>` runs the client here and the server on the Coder
# workspace: agents and ~/.config/herdr/session.json stay on the box that has
# the code, while your clipboard and notifications stay local. Keybindings are
# deliberately *not* local — see dev().
#
# Depends on `coder config-ssh` having written the `Host coder.*` block into
# ~/.ssh/config — already true if `ssh coder.<workspace>` works. That block's
# ProxyCommand strips the `coder.` prefix, so the alias is `coder.<name>`.

if ! command -v coder &> /dev/null; then
  print -u2 "local/mac.zsh: coder CLI not found — 'dev' not defined"
  return 0 2>/dev/null || true
fi

# Print "<name>  <status>" for every workspace you own.
_coder_ws_list() {
  coder list --output json 2>/dev/null \
    | jq -r '.[] | [.name, .latest_build.status] | @tsv' \
    | awk -F'\t' '{ printf "%-42s %s\n", $1, $2 }'
}

# Shared picker. Echoes the chosen workspace name, or nothing if cancelled.
_coder_ws_pick() {
  local cmd
  for cmd in coder jq fzf; do
    if ! command -v "$cmd" &> /dev/null; then
      print -u2 "coder picker: '$cmd' not installed"
      return 1
    fi
  done

  local list
  list=$(_coder_ws_list)
  if [ -z "$list" ]; then
    print -u2 "coder picker: no workspaces returned — try 'coder login'"
    return 1
  fi

  print -r -- "$list" | fzf --height=40% --reverse --ansi \
    --prompt='coder workspace > ' \
    --header='enter to connect — a stopped workspace is started on connect' \
    | awk '{ print $1 }'
}

# dev — the one command. Lists your Coder workspaces, and the one you pick
# becomes a Herdr session: client here, server (and agents) on that box.
#   dev              pick from a list
#   dev <name>       skip the picker and go straight there
#
# --remote-keybindings server is the important flag. It defaults to `local`,
# which means the client matches keys against the *Mac's* config.toml and the
# one install.sh writes on the box is ignored for input entirely — so binding a
# key or a newly installed plugin action in this repo's config.toml had no
# effect until you also hand-copied it here. Pointing key resolution at the
# server makes .config/herdr/config.toml the single source of truth: every new
# Coder workspace gets it from install.sh, and a change goes live with
# `herdr server reload-config` (alias `hreload`, or prefix+shift+r) without
# reattaching. The Mac keeps clipboard, notifications, and the theme.
dev() {
  # Nesting is blocked by default, so fail with a useful message rather than
  # letting herdr refuse after the ssh handshake.
  if [ -n "$HERDR_ENV" ]; then
    print -u2 "dev: already inside Herdr — detach first (prefix q)"
    return 1
  fi

  local ws="$1"
  if [ -z "$ws" ]; then
    ws=$(_coder_ws_pick) || return 1
    [ -z "$ws" ] && return 0
  fi
  herdr --remote "coder.$ws" --remote-keybindings server
}

# dev-ssh — same picker, but a plain SSH shell instead of Herdr.
dev-ssh() {
  local ws="$1"
  if [ -z "$ws" ]; then
    ws=$(_coder_ws_pick) || return 1
    [ -z "$ws" ] && return 0
  fi
  ssh "coder.$ws"
}

# dev-ls — just print the workspaces and their status.
# A function rather than an alias, so it also works when sourced and called in
# the same breath (aliases are expanded at parse time, functions are not).
dev-ls() { _coder_ws_list; }

# dev-version — compare local and remote Herdr versions.
#
# Worth checking before you assume a session is safe. `herdr --remote` compares
# its protocol version against the remote server's; on a mismatch it replaces the
# remote binary and restarts the server, which ends whatever was running there.
# Keeping the two in step is what avoids that.
#   dev-version <name>
dev-version() {
  local ws="$1"
  if [ -z "$ws" ]; then
    ws=$(_coder_ws_pick) || return 1
    [ -z "$ws" ] && return 0
  fi
  printf 'local   %s\n' "$(herdr --version 2>/dev/null || echo 'not installed')"
  printf 'remote  %s\n' "$(ssh "coder.$ws" '$HOME/.local/bin/herdr --version' 2>/dev/null \
    || echo 'not installed / not reachable')"
}
