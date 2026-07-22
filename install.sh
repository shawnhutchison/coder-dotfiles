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
    zsh git curl jq ripgrep fd-find unzip tmux build-essential

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

elif [ "$OS" = "Darwin" ]; then
  if command -v brew &> /dev/null; then
    brew install ripgrep fd fzf jq neovim tmux 2>/dev/null || true
  else
    echo "  Homebrew not found — install from https://brew.sh"
  fi
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
mkdir -p "$HOME/.claude/commands"
cp "$DOTFILES_DIR/.claude/commands/install-my-plugins.md" "$HOME/.claude/commands/install-my-plugins.md"
echo "  Claude Code configured"

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

# --- tmux config ---
echo ""
echo "Configuring tmux..."
cp "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
echo "  tmux configured"

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
echo "After authenticating with Claude, run /install-my-plugins to install Claude Code plugins."
echo ""
