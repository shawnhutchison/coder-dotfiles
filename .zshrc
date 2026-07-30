# --- Path ---
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$HOME/.npm-global/bin:$PATH"

# --- Locale ---
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# --- Editor ---
if command -v nvim &> /dev/null; then
  export EDITOR="nvim"
else
  export EDITOR="${EDITOR:-vim}"
fi
export VISUAL="$EDITOR"

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt share_history

# --- Completion ---
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

# --- Prompt with git branch ---
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt prompt_subst
PROMPT='%F{cyan}%n%f@%F{yellow}%m%f:%F{green}%~%f%F{magenta}${vcs_info_msg_0_}%f $ '

# --- Key bindings ---
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# --- Aliases: navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ls='ls --color=auto 2>/dev/null || ls'
alias ll='ls -lah'
alias la='ls -A'

# --- Aliases: git ---
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias glg='git log --graph --oneline --decorate --all'

# --- Aliases: editor ---
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# --- Aliases: herdr ---
alias h='herdr'                     # start / reattach the default session
alias hs='herdr --session'          # hs <name>  — start or reattach a named session
alias hl='herdr session list'       # list sessions
alias hstop='herdr session stop'    # hstop <name>  — stop a session, keep its state
alias hrm='herdr session delete'    # hrm <name>    — delete a session and its state
alias ha='herdr agent list'         # what every agent is currently doing
alias hcfg='${EDITOR:-nvim} ~/.config/herdr/config.toml'
alias hreload='herdr server reload-config'

# --- Coder workspaces + Herdr remote attach ---------------------------------
# Herdr splits into a client (the UI) and a server (the panes, agents, layout).
# `herdr --remote <host>` runs the client here and the server on the Coder
# workspace: agents and ~/.config/herdr/session.json stay on the box that has
# the code, while your clipboard and keybindings stay local.
#
# Depends on `coder config-ssh` having written the `Host coder.*` block into
# ~/.ssh/config — already true if `ssh coder.<workspace>` works. That block's
# ProxyCommand strips the `coder.` prefix, so the alias is `coder.<name>`.

# Only define these where they make sense. The same .zshrc is sourced on the
# Coder workspace itself, where the coder CLI isn't installed and picking a Coder
# workspace from inside one is meaningless — better that `dev` simply not exist
# there than offer a command that always fails.
if command -v coder &> /dev/null; then

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
  herdr --remote "coder.$ws"
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

fi  # command -v coder

# --- Aliases: misc ---
alias reload='exec zsh'
alias cls='clear'

# --- fzf ---
if command -v fzf &> /dev/null; then
  eval "$(fzf --zsh 2>/dev/null)" || true
fi

# --- Local overrides ---
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# --- Herdr autostart (opt-in) -----------------------------------------------
# Land straight in Herdr when you open a shell on this box. Pairs well with a
# Coder workspace that restarts nightly: the first launch after boot restores
# your layout from ~/.config/herdr/session.json.
#
# Off by default because it surprises non-interactive logins. Enable with:
#   echo 'export HERDR_AUTOSTART=1' >> ~/.zshrc.local
#
# Must stay below the .zshrc.local source above, so the flag is already set.
# Guards: opted in, interactive shell, not already inside a Herdr pane
# (HERDR_ENV=1 is set in every pane, and nesting is blocked by default), and
# herdr is actually installed.
if [ -n "$HERDR_AUTOSTART" ] && [[ $- == *i* ]] \
  && [ -z "$HERDR_ENV" ] && command -v herdr &> /dev/null; then
  exec herdr
fi
