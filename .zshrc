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

# The `dev` command — pick a Coder workspace and attach a Herdr client to it —
# is deliberately NOT here. It runs on your own machine, not in the workspace,
# so it lives in local/mac.zsh, which install.sh never copies.

# --- Aliases: coder ---
# Coder's GitHub external-auth token expires after about 8 hours; this mints a
# fresh one and hands it to gh.
alias gh-auth-refresh='coder external-auth access-token coder-auth | gh auth login -h github.com --with-token'

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
