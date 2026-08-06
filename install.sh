#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

echo "=== Coder Dotfiles Installation ==="
echo ""

# --- Core packages ---
echo "Installing core packages..."

if [ "$OS" = "Linux" ]; then
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends \
    zsh git curl jq ripgrep fd-find unzip build-essential

  if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
  fi

  # Neovim — apt ships an old version, so install the latest stable tarball
  # into ~/.local/nvim (no root needed; ~/.local/bin is already on PATH).
  if ! command -v nvim &> /dev/null; then
    NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    if ! curl -fsSLo /tmp/nvim.tar.gz "$NVIM_URL"; then
      # Fall back to the pre-0.10.4 asset name.
      curl -fsSLo /tmp/nvim.tar.gz \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
    fi
    rm -rf "$HOME/.local/nvim"
    mkdir -p "$HOME/.local/nvim" "$HOME/.local/bin"
    tar -xzf /tmp/nvim.tar.gz -C "$HOME/.local/nvim" --strip-components=1
    ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    rm /tmp/nvim.tar.gz
    echo "  Installed Neovim"
  else
    echo "  Neovim already installed"
  fi

  if ! command -v fzf &> /dev/null; then
    FZF_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -fsSLo /tmp/fzf.tar.gz \
      "https://github.com/junegunn/fzf/releases/latest/download/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
    mkdir -p ~/.local/bin
    tar -xzf /tmp/fzf.tar.gz -C ~/.local/bin fzf
    rm /tmp/fzf.tar.gz
    echo "  Installed fzf ${FZF_VERSION}"
  fi

  # glow — renders markdown in the terminal. Agents produce a lot of .md
  # analyses; `glow` with no argument browses every markdown file under the
  # current tree. Not in Ubuntu's default repos, and adding Charm's apt repo
  # needs root, so take the release tarball into ~/.local/bin like fzf above.
  if ! command -v glow &> /dev/null; then
    case "$(uname -m)" in
      x86_64|amd64)  GLOW_ARCH="x86_64" ;;
      aarch64|arm64) GLOW_ARCH="arm64" ;;
      *)             GLOW_ARCH="" ;;
    esac

    if [ -n "$GLOW_ARCH" ]; then
      GLOW_VERSION=$(curl -s "https://api.github.com/repos/charmbracelet/glow/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
      if [ -n "$GLOW_VERSION" ] && curl -fsSLo /tmp/glow.tar.gz \
        "https://github.com/charmbracelet/glow/releases/latest/download/glow_${GLOW_VERSION}_Linux_${GLOW_ARCH}.tar.gz"; then
        mkdir -p ~/.local/bin
        # The binary sits inside a versioned directory in the archive.
        tar -xzf /tmp/glow.tar.gz -C ~/.local/bin --strip-components=1 \
          "glow_${GLOW_VERSION}_Linux_${GLOW_ARCH}/glow"
        rm /tmp/glow.tar.gz
        echo "  Installed glow ${GLOW_VERSION}"
      else
        echo "  Skipped glow (download failed)"
      fi
    else
      echo "  Skipped glow (unsupported arch $(uname -m))"
    fi
  fi

  # lazygit — full-screen git TUI, bound to a Herdr popup (prefix+alt+g). Same
  # tarball-into-~/.local/bin pattern as fzf/glow.
  if ! command -v lazygit &> /dev/null; then
    case "$(uname -m)" in
      x86_64|amd64)  LG_ARCH="x86_64" ;;
      aarch64|arm64) LG_ARCH="arm64" ;;
      *)             LG_ARCH="" ;;
    esac

    if [ -n "$LG_ARCH" ]; then
      LG_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
      if [ -n "$LG_VERSION" ] && curl -fsSLo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VERSION}_Linux_${LG_ARCH}.tar.gz"; then
        mkdir -p ~/.local/bin
        # Archive has the binary at its root alongside LICENSE/README.
        tar -xzf /tmp/lazygit.tar.gz -C ~/.local/bin lazygit
        rm /tmp/lazygit.tar.gz
        echo "  Installed lazygit ${LG_VERSION}"
      else
        echo "  Skipped lazygit (download failed)"
      fi
    else
      echo "  Skipped lazygit (unsupported arch $(uname -m))"
    fi
  fi

elif [ "$OS" = "Darwin" ]; then
  if command -v brew &> /dev/null; then
    brew install ripgrep fd fzf jq neovim glow lazygit 2>/dev/null || true
  else
    echo "  Homebrew not found — install from https://brew.sh"
  fi
fi

# --- Herdr ---
# Terminal workspace manager (replaces tmux). Unlike tmux, Herdr persists its
# session layout to ~/.config/herdr/session.json and restores it when the server
# next starts — which is what makes a nightly Coder shutdown survivable.
echo ""
echo "Installing Herdr..."
if ! command -v herdr &> /dev/null; then
  # Official installer; drops the binary in ~/.local/bin (already on PATH).
  curl -fsSL https://herdr.dev/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  echo "  Installed Herdr ($(herdr --version 2>/dev/null || echo unknown))"
else
  # Already present — upgrade in place so a re-provisioned box lands on the
  # latest Herdr rather than drifting (see CHEATSHEET, "Keep the two Herdr
  # versions in step"). This also clears the reviewr plugin's version gate: its
  # manifest sets min_herdr_version = 0.7.5, so an older Herdr makes the review
  # pane refuse to start. Non-fatal: a no-op or a network blip shouldn't abort
  # the install under `set -e`.
  echo "  Herdr already installed ($(herdr --version 2>/dev/null || echo unknown)); updating..."
  herdr update || true
  echo "  Herdr now at $(herdr --version 2>/dev/null || echo unknown)"
fi


# --- Claude Code CLI ---
echo ""
echo "Installing Claude Code..."
if ! command -v claude &> /dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
  export PATH="$HOME/.claude/bin:$PATH"
  echo "  Installed Claude Code CLI"
else
  echo "  Claude Code already installed"
fi

# --- Claude Code config ---
echo ""
echo "Configuring Claude Code..."
mkdir -p "$HOME/.claude"
[ ! -f "$HOME/.claude/settings.json" ] && cp "$DOTFILES_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
[ ! -f "$HOME/.claude/CLAUDE.md" ] && cp "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
cp "$DOTFILES_DIR/.claude/statusline.sh" "$HOME/.claude/statusline.sh"
chmod +x "$HOME/.claude/statusline.sh"
echo "  Claude Code configured"

# --- Herdr <-> Claude Code integration ---
# Installs ~/.claude/hooks/herdr-agent-state.sh and *merges* a hooks entry into
# ~/.claude/settings.json. This is why it runs after the block above: that copy
# would otherwise clobber the hook registration on a fresh box.
#
# The hook is what lets Herdr show Claude's live state (working/blocked/done) in
# the sidebar, and what lets `resume_agents_on_restore` reattach a pane to its
# original conversation after the Coder workspace restarts.
echo ""
echo "Wiring Herdr to Claude Code..."
if command -v herdr &> /dev/null; then
  herdr integration install claude && echo "  Agent-state hook installed"
else
  echo "  Skipped — herdr not on PATH"
fi

# --- Herdr plugins ---
# reviewr (github.com/persiyanov/herdr-reviewr): a code-review sidebar for an
# agent's diff — view changes, add line comments, send them back to the agent.
# `herdr plugin install` fetches the prebuilt binary from the plugin's GitHub
# release; no Rust toolchain needed. Requires Herdr >= 0.7.5 (the update above).
echo ""
echo "Installing Herdr plugins..."
if command -v herdr &> /dev/null; then
  if herdr plugin list 2>/dev/null | grep -q "persiyanov.reviewr"; then
    echo "  reviewr already installed"
  else
    herdr plugin install -y persiyanov/herdr-reviewr \
      && echo "  Installed reviewr" \
      || echo "  Skipped reviewr (install failed)"
  fi

  # Theme reviewr to match nvim/Herdr/Ghostty. The plugin reads config.toml from
  # the directory `herdr plugin config-dir` reports — resolved here rather than
  # hardcoded. We ship only `theme`: per the plugin's config spec a single bad
  # key invalidates the whole file and the pane then does no work.
  REVIEWR_CFG_DIR="$(herdr plugin config-dir persiyanov.reviewr 2>/dev/null)"
  if [ -n "$REVIEWR_CFG_DIR" ]; then
    mkdir -p "$REVIEWR_CFG_DIR"
    cp "$DOTFILES_DIR/.config/herdr/plugins/persiyanov.reviewr.toml" \
      "$REVIEWR_CFG_DIR/config.toml"
    echo "  reviewr themed (Tokyo Night)"
  fi
else
  echo "  Skipped Herdr plugins — herdr not on PATH"
fi

# --- Neovim config ---
echo ""
echo "Configuring Neovim..."
mkdir -p "$HOME/.config/nvim"
cp "$DOTFILES_DIR/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
# Pre-install plugins headlessly so the first launch is instant (best effort).
# Must block on `wait = true` -- the `+Lazy! sync` command form kicks off
# clone/checkout/build as async jobs and returns immediately, so a bare `+qa`
# can quit before a plugin's branch checkout finishes, leaving it cloned but
# stuck on the wrong branch (e.g. nvim-treesitter's default `main`, which
# lacks the classic `.configs` API this config relies on).
if command -v nvim &> /dev/null; then
  nvim --headless -c "lua require('lazy').sync({ wait = true, show = false })" -c "qa" 2>/dev/null || true
  echo "  Neovim configured (plugins synced)"
else
  echo "  Neovim config copied (plugins will install on first launch)"
fi

# --- Herdr config ---
# Copy the single config file only. ~/.config/herdr/ also holds session.json and
# session-history.json — the restore state for workspaces, layouts and pane
# scrollback — so this must never remove or replace the directory itself, or a
# re-run of install.sh would throw away the sessions we're trying to preserve.
echo ""
echo "Configuring Herdr..."
mkdir -p "$HOME/.config/herdr"
cp "$DOTFILES_DIR/.config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
if [ -f "$HOME/.config/herdr/session.json" ]; then
  echo "  Herdr configured (existing session state left intact)"
else
  echo "  Herdr configured"
fi

# Pick up config changes if a server is already running; harmless otherwise.
if command -v herdr &> /dev/null; then
  herdr server reload-config > /dev/null 2>&1 || true
fi

# --- Zsh config ---
echo ""
echo "Setting up zsh..."
touch "$HOME/.zshrc"
if ! grep -q "coder-dotfiles/.zshrc" "$HOME/.zshrc" 2>/dev/null; then
  echo "source $DOTFILES_DIR/.zshrc" >> "$HOME/.zshrc"
  echo "  Added source line to ~/.zshrc"
else
  echo "  ~/.zshrc already sources dotfiles"
fi

if [ "$OS" = "Linux" ] && [ "$SHELL" != "$(which zsh)" ]; then
  ZSH_PATH="$(which zsh)"
  if grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    chsh -s "$ZSH_PATH" 2>/dev/null || true
  fi
fi

# --- Git config ---
echo ""
echo "Setting up git..."

add_git_alias() {
  local name="$1" cmd="$2"
  git config --global --get "alias.$name" > /dev/null 2>&1 \
    || git config --global "alias.$name" "$cmd"
}

add_git_alias "co"      "checkout"
add_git_alias "br"      "branch"
add_git_alias "st"      "status"
add_git_alias "cm"      "commit"
add_git_alias "ff"      "pull --ff-only"
add_git_alias "lg"      "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
add_git_alias "last"    "log -1 HEAD"
add_git_alias "unstage" "reset HEAD --"

git config --global rerere.enabled true
git config --global pull.rebase true
echo "  Git configured"

# --- Done ---
echo ""
echo "======================================="
echo "  Installation complete!"
echo "======================================="
echo ""
echo "Auth still needed:"
echo "  gh auth login     # GitHub CLI"
echo "  claude            # Claude Code (prompts on first run)"
echo ""
echo "Then start your workspace:"
echo "  herdr             # starts the server and restores your last layout"
echo ""
echo "Prefix is Ctrl-Space. Press Ctrl-Space then ? for the full key list."
echo "See CHEATSHEET.md for the workflow."
echo ""
