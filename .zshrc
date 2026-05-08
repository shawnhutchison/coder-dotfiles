# --- Path ---
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$HOME/.npm-global/bin:$PATH"

# --- Locale ---
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# --- Editor ---
export EDITOR="${EDITOR:-vim}"
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

# --- Aliases: misc ---
alias reload='exec zsh'
alias cls='clear'

# --- fzf ---
if command -v fzf &> /dev/null; then
  eval "$(fzf --zsh 2>/dev/null)" || true
fi

# --- Local overrides ---
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
