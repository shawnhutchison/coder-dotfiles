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
    zsh git curl jq ripgrep fd-find unzip

  if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
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
    brew install ripgrep fd fzf jq 2>/dev/null || true
  else
    echo "  Homebrew not found — install from https://brew.sh"
  fi
fi

# --- GitHub CLI ---
echo ""
echo "Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
  if [ "$OS" = "Linux" ]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli-stable.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y gh
  elif [ "$OS" = "Darwin" ]; then
    brew install gh 2>/dev/null || true
  fi
  echo "  Installed gh CLI"
else
  echo "  gh CLI already installed"
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

# --- Claude Code plugins ---
echo ""
echo "Installing Claude Code plugins..."
for plugin in \
  ruby-lsp \
  typescript-lsp \
  code-review \
  code-simplifier \
  explanatory-output-style \
  learning-output-style \
  commit-commands; do
  claude plugins install "${plugin}@claude-plugins-official" 2>/dev/null \
    && echo "  Installed ${plugin}" \
    || echo "  Skipped ${plugin} (may already be installed)"
done

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
