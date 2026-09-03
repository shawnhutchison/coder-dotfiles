#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

# Surface prior ~/.local/bin installs to the `command -v` skip-guards below — the
# install shell may not have it on PATH yet, which would otherwise re-download
# tools that are already present.
export PATH="$HOME/.local/bin:$PATH"

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

  # tree-sitter CLI — nvim-treesitter's `main` branch shells out to it for every
  # parser build (>= 0.26.1; upstream is explicit that it must not be the npm
  # build). Without it `require('nvim-treesitter').install()` produces no parsers
  # and you silently lose all syntax highlighting, so this is a real dependency
  # of .config/nvim/init.lua, not a nicety. The C compiler it shells out to in
  # turn comes from build-essential above.
  #
  # Two ways in, tried in order, because the fast one does not always run here:
  #
  #  1. The release binary. Upstream builds linux-x64 on ubuntu-24.04 against
  #     x86_64-unknown-linux-gnu — no musl asset, no `cross` — so the binary
  #     needs GLIBC_2.39 and dies on an Ubuntu 22.04 box (glibc 2.35) with
  #       tree-sitter: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.39'
  #       not found (required by tree-sitter)
  #     which surfaces as an `[nvim-treesitter/install/...]` error on every nvim
  #     start. Pinning an older tag is not an escape: every release meeting
  #     nvim-treesitter's 0.26.1 floor is built the same way.
  #  2. cargo. Slow (a few minutes) and it pulls a Rust toolchain, but it links
  #     against the glibc actually on the box, so it works everywhere.
  #
  # The guard *runs* `tree-sitter --version` rather than testing `command -v`.
  # An existence test is what let the broken download above survive every
  # re-provision: the file was there, so the block skipped, forever.
  TS_BIN="$HOME/.local/bin/tree-sitter"
  [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

  if tree-sitter --version &> /dev/null; then
    echo "  tree-sitter CLI already installed ($(tree-sitter --version))"
  else
    rm -f "$TS_BIN"
    hash -r 2> /dev/null || true

    case "$(uname -m)" in
      x86_64|amd64)  TS_ARCH="x64" ;;
      aarch64|arm64) TS_ARCH="arm64" ;;
      *)             TS_ARCH="" ;;
    esac
    [ -z "$TS_ARCH" ] && echo "  No release binary for $(uname -m); going to source"

    if [ -n "$TS_ARCH" ] && curl -fsSLo /tmp/tree-sitter.gz \
      "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-${TS_ARCH}.gz"; then
      mkdir -p "$HOME/.local/bin"
      gunzip -c /tmp/tree-sitter.gz > "$TS_BIN"
      chmod +x "$TS_BIN"
      rm -f /tmp/tree-sitter.gz
    fi

    # Test-run it. A binary that unpacked fine but cannot load its libc is worse
    # than none: nvim-treesitter reports a build error on every file open.
    if "$TS_BIN" --version &> /dev/null; then
      echo "  Installed tree-sitter CLI $("$TS_BIN" --version)"
    else
      rm -f "$TS_BIN"

      if ! command -v cargo &> /dev/null; then
        echo "  Release binary needs a newer glibc than this box has; installing"
        echo "  Rust to build the tree-sitter CLI from source..."
        # --profile minimal: rustc + cargo, no docs or clippy. --no-modify-path
        # keeps rustup out of .zshrc — the PATH export above is what finds cargo
        # here and on every later run of this script.
        if curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
          | sh -s -- -y --profile minimal --no-modify-path > /dev/null 2>&1; then
          export PATH="$HOME/.cargo/bin:$PATH"
          echo "  Installed $(rustc --version 2> /dev/null || echo Rust)"
        else
          echo "  Skipped Rust (rustup install failed)"
        fi
      fi

      if command -v cargo &> /dev/null; then
        # tree-sitter-cli's default `qjs-rt` feature pulls rquickjs-sys, whose
        # build script runs bindgen and dlopens libclang.so. Without it the
        # build dies at:
        #   Unable to find libclang: "couldn't find any valid shared libraries
        #   matching: ['libclang.so', ...]"
        # Not in the apt list at the top of this script because it is ~100MB and
        # only this fallback needs it.
        echo "  Installing libclang-dev (bindgen needs it)..."
        sudo apt-get install -y --no-install-recommends libclang-dev > /dev/null 2>&1 \
          || echo "  Warning: libclang-dev install failed; the build below will too"

        echo "  Building tree-sitter CLI from source (a few minutes, once per box)..."
        # stdout muted, stderr left alone on purpose: cargo's progress lines go
        # to stderr, and a silent multi-minute build inside Coder's dotfiles
        # runner is indistinguishable from a hang.
        if cargo install --locked --root "$HOME/.local" tree-sitter-cli > /dev/null; then
          echo "  Installed tree-sitter CLI $("$TS_BIN" --version)"
        else
          echo "  Failed to build tree-sitter CLI — nvim will have no treesitter"
          echo "  highlighting until this succeeds:"
          echo "    cargo install --locked --root ~/.local tree-sitter-cli"
        fi
      else
        echo "  Skipped tree-sitter CLI (no cargo) — nvim will have no treesitter"
        echo "  highlighting"
      fi
    fi
  fi

  if ! command -v fzf &> /dev/null; then
    # `|| true`: a bare `VAR=$(...)` that exits non-zero (grep no-match on an API
    # rate-limit/error page) would trip `set -e` and abort the whole install.
    FZF_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || true)
    if [ -n "$FZF_VERSION" ] && curl -fsSLo /tmp/fzf.tar.gz \
      "https://github.com/junegunn/fzf/releases/latest/download/fzf-${FZF_VERSION}-linux_amd64.tar.gz"; then
      mkdir -p ~/.local/bin
      tar -xzf /tmp/fzf.tar.gz -C ~/.local/bin fzf
      rm /tmp/fzf.tar.gz
      echo "  Installed fzf ${FZF_VERSION}"
    else
      echo "  Skipped fzf (download failed)"
    fi
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
      GLOW_VERSION=$(curl -s "https://api.github.com/repos/charmbracelet/glow/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || true)
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
      LG_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || true)
      # Note lowercase `linux` — jesseduffield names assets `lazygit_<v>_linux_<arch>`,
      # unlike charmbracelet's capital `Linux` for glow above. Case matters: GitHub
      # release asset URLs are case-sensitive, so `Linux` here 404s every time.
      if [ -n "$LG_VERSION" ] && curl -fsSLo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VERSION}_linux_${LG_ARCH}.tar.gz"; then
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

# --- SSH host trust for github.com ---
# A fresh Coder box has no ~/.ssh at all. Coder injects the git identity through
# GIT_SSH_COMMAND=/tmp/coder.XXXXXX/coder gitssh --, and that wrapper handles
# *authentication* only — it never establishes host trust. So the first
# `git clone git@github.com:...` aborts with "Host key verification failed",
# which is what breaks `claude plugin marketplace add` on a new workspace.
# HTTPS is not a workaround: private repos need credentials git has no helper for.
#
# The keys come from GitHub's meta API, so the trust anchor is CA verification of
# api.github.com. Deliberately no fingerprint pinning: it would add nothing on
# top of TLS and would hard-fail whenever GitHub rotates a key, as it did to the
# RSA key in March 2023. Runs on both platforms — the guard below makes it a
# no-op on a Mac that already trusts github.com.
echo ""
echo "Trusting github.com SSH host keys..."
if command -v curl &> /dev/null && command -v jq &> /dev/null \
  && command -v ssh-keygen &> /dev/null; then
  # `ssh-keygen -F` exits non-zero when the host is absent — the normal case on a
  # fresh box — so it must be tested, never left bare under `set -e`. `-f` is not
  # optional: with no explicit file ssh-keygen resolves ~ from the passwd entry
  # rather than $HOME, so the check could read a different file than the append
  # below writes, and every re-run would add another copy of the keys.
  if ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" > /dev/null 2>&1; then
    echo "  github.com already trusted"
  elif ! curl -fsS https://api.github.com/meta -o /tmp/gh_meta.json; then
    echo "  Skipped — could not reach api.github.com; SSH clones will fail until"
    echo "  ssh-keyscan github.com >> ~/.ssh/known_hosts is run by hand"
  else
    # Keep only lines that actually look like an SSH public key. Without this, a
    # rate-limit or error payload would land in known_hosts as garbage.
    jq -r '.ssh_keys[]?' /tmp/gh_meta.json 2>/dev/null \
      | grep -E '^(ssh-|ecdsa-)' \
      | sed 's/^/github.com /' > /tmp/gh_keys || true
    rm -f /tmp/gh_meta.json

    if [ -s /tmp/gh_keys ]; then
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      # Append, never truncate: known_hosts may already hold other hosts.
      cat /tmp/gh_keys >> "$HOME/.ssh/known_hosts"
      chmod 600 "$HOME/.ssh/known_hosts"
      echo "  Added $(grep -c . /tmp/gh_keys) github.com host key(s)"
    else
      echo "  Skipped — api.github.com returned no usable host keys"
    fi
    rm -f /tmp/gh_keys
  fi
else
  echo "  Skipped — curl, jq or ssh-keygen missing"
fi

# --- Herdr ---
# Terminal workspace manager (replaces tmux). Unlike tmux, Herdr persists its
# session layout to ~/.config/herdr/session.json and restores it when the server
# next starts — which is what makes a nightly Coder shutdown survivable.
#
# Pinned to a version, deliberately. This used to run `herdr update` on every
# provision; on 2026-08-24 that walked the box to 0.8.2, and 0.8.2 regressed the
# shutdown path. It now reaps every pane before the server snapshots, so a
# machine stop leaves zero live panes, Herdr reads that as "the user closed
# everything", and *deletes* session.json rather than saving it. Same event, two
# versions, from the box's own herdr-server.log:
#
#   0.8.0  19:46:50.397  server shutdown initiated
#          19:46:50.546  session saved  workspaces=1
#          19:46:50.546  pane session terminated pane=2      <- after the save
#
#   0.8.2  02:40:47.245  pane session terminated pane=3, pane=1
#          02:40:47.245  server shutdown initiated           <- zero panes left
#          02:40:47.320  session cleared
#
# The matching 0.8.2 changelog entry is #2612, "Server stop requests now bypass
# pane and API traffic". Raise the pin once a release fixes this — and raise the
# Mac's at the same time (see local/mac.zsh). `herdr --remote` resyncs the
# server binary to the *client's* version on attach, so a one-sided pin is
# undone the next time you run `dev`.
#
# `[update] version_check = false` in .config/herdr/config.toml is the other
# half: without it Herdr's own half-hourly check walks the pin forward again.
HERDR_VERSION="0.8.0"

echo ""
echo "Installing Herdr $HERDR_VERSION..."
case "$(uname -m)" in
  x86_64|amd64)  HERDR_ARCH="x86_64" ;;
  aarch64|arm64) HERDR_ARCH="aarch64" ;;
  *)             HERDR_ARCH="" ;;
esac
# This block is outside the Linux/Darwin split above, so name the platform
# rather than hardcoding linux — the asset names are herdr-<os>-<arch>.
[ "$OS" = "Darwin" ] && HERDR_OS="macos" || HERDR_OS="linux"
mkdir -p "$HOME/.local/bin"

if [ "$(herdr --version 2> /dev/null | awk '{print $2}')" = "$HERDR_VERSION" ]; then
  echo "  Herdr already at $HERDR_VERSION"
elif [ -z "$HERDR_ARCH" ]; then
  echo "  Skipped — no Herdr release asset for $(uname -m)"
elif curl -fsSLo "$HOME/.local/bin/herdr.new" \
  "https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/herdr-${HERDR_OS}-${HERDR_ARCH}"; then
  # Staged beside the target and renamed, not downloaded over it: rename is
  # atomic on the same filesystem and works even while a server holds the old
  # binary open, which an in-place write would refuse with "Text file busy".
  chmod +x "$HOME/.local/bin/herdr.new"
  mv "$HOME/.local/bin/herdr.new" "$HOME/.local/bin/herdr"
  hash -r 2> /dev/null || true
  echo "  Installed Herdr $(herdr --version 2> /dev/null || echo unknown)"
else
  rm -f "$HOME/.local/bin/herdr.new"
  echo "  Skipped — could not download Herdr $HERDR_VERSION"
  command -v herdr &> /dev/null \
    && echo "  Leaving $(herdr --version 2> /dev/null || echo unknown) in place"
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

# --- Claude Code output style ---
# Symlink rather than copy, for the reason in 046b0fc: a cp goes stale silently, so an
# edit to the style in this repo would never reach the box. mkdir -p first — without an
# existing directory, `ln -sf` creates a *file* named output-styles pointing at the
# style, and Claude Code then finds no styles at all.
echo ""
echo "Installing Claude Code output style..."
mkdir -p "$HOME/.claude/output-styles"
ln -sf "$DOTFILES_DIR/.claude/output-styles/intuitive.md" \
  "$HOME/.claude/output-styles/intuitive.md"

# Activation lives in settings.json, which the copy above skips on any box that already
# has one — so merge the single key instead of copying the file. Same merge-don't-clobber
# approach `herdr integration install claude` uses on this file below. The value must
# match the style's frontmatter `name:` byte for byte.
if [ -f "$HOME/.claude/settings.json" ] && command -v jq &> /dev/null; then
  # A literal path, not `$(mktemp)` — a bare `VAR=$(...)` that exits non-zero aborts the
  # whole install under `set -e` (see the fzf block). Beside the target on
  # purpose: same filesystem, so the `mv` below is atomic.
  SETTINGS_TMP="$HOME/.claude/settings.json.tmp"
  if jq '.outputStyle = "intuitive"' "$HOME/.claude/settings.json" > "$SETTINGS_TMP"; then
    mv "$SETTINGS_TMP" "$HOME/.claude/settings.json"
    echo "  Output style set to 'intuitive'"
  else
    rm -f "$SETTINGS_TMP"
    echo "  Skipped activation — ~/.claude/settings.json is not valid JSON"
  fi
else
  echo "  Skipped activation — no settings.json or no jq"
fi

# --- Claude Code skills ---
# Symlinked for the same reason as the output style: a cp goes stale silently.
# `ln -sfn`, not `ln -sf` — the target is a directory, and without -n a second run
# resolves *through* the existing symlink and creates skills/docs-pane/docs-pane.
echo ""
echo "Installing Claude Code skills..."
mkdir -p "$HOME/.claude/skills"
for skill_dir in "$DOTFILES_DIR"/.claude/skills/*/; do
  [ -d "$skill_dir" ] || continue
  ln -sfn "${skill_dir%/}" "$HOME/.claude/skills/$(basename "$skill_dir")"
  echo "  Linked $(basename "$skill_dir")"
done

# Skill helper scripts go on PATH so SKILL.md can call them by bare name. The
# skill is used from whatever repo is being reviewed, not from this one, so a
# repo-relative path would not resolve.
mkdir -p "$HOME/.local/bin"
for skill_bin in "$DOTFILES_DIR"/.claude/skills/*/bin/*; do
  [ -f "$skill_bin" ] || continue
  chmod +x "$skill_bin"
  ln -sfn "$skill_bin" "$HOME/.local/bin/$(basename "$skill_bin")"
done

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

# --- Language servers for Claude Code's LSP plugins ---
# Every LSP plugin in the roadrunner-agent-skills marketplace (typescript-lsp,
# pyright-lsp, terraform-lsp, ...) only *declares* a command to spawn; none of
# them install a binary. So `/plugin install typescript-lsp` reports success and
# then every LSP call on a .ts/.tsx file fails with
#   Executable not found in $PATH: "typescript-language-server"
# `typescript` ships alongside because the server needs a tsc to load. A
# project's own node_modules/typescript still wins for files inside that project,
# so this copy only serves files outside one.
#
# ruby-lsp needs nothing here: it arrives as a gem in the workspace image's asdf
# ruby, already shimmed at ~/.asdf/shims/ruby-lsp.
#
# --prefix is the point of this block, not a detail. A plain `npm i -g` lands in
# whichever nodejs asdf currently pins, so the binary vanishes from PATH the
# moment a project's .tool-versions moves the version. ~/.npm-global/bin is on
# PATH from .zshrc and survives that.
echo ""
echo "Installing language servers..."
# Node reaches PATH on the box through asdf's shims, and the init line that adds
# them lives in an interactive shell's rc — which Coder's dotfiles runner is not.
# Without this the `command -v npm` guard below skips on exactly the fresh-box
# case this block exists for. Harmless when asdf is absent.
[ -d "$HOME/.asdf/shims" ] && export PATH="$HOME/.asdf/shims:$PATH"

TS_LS="$HOME/.npm-global/bin/typescript-language-server"
if ! command -v npm &> /dev/null; then
  echo "  Skipped — no npm on PATH (this repo installs no node runtime)"
elif [ -x "$TS_LS" ]; then
  echo "  typescript-language-server already installed ($("$TS_LS" --version 2>/dev/null || echo unknown))"
elif npm install -g --prefix "$HOME/.npm-global" \
  --no-audit --no-fund --fetch-retries=2 --fetch-retry-maxtimeout=20000 \
  typescript-language-server typescript > /dev/null 2>&1; then
  export PATH="$HOME/.npm-global/bin:$PATH"
  echo "  Installed typescript-language-server $("$TS_LS" --version 2>/dev/null || echo unknown)"
else
  echo "  Skipped typescript-language-server (npm install failed)"
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
# stuck on whatever branch it landed on. Several specs in init.lua pin one
# (nvim-treesitter `main`, neo-tree `v3.x`), and a half-applied checkout there
# means a plugin whose API doesn't match the config that calls it.
#
# If the repo carries a lockfile, install to those exact revisions instead of
# syncing to whatever is newest. That is the one lever that prevents a repeat of
# the nvim-treesitter break: upstream moving no longer changes your box until you
# deliberately refresh the lockfile. To refresh it: `:Lazy update` on the box,
# then copy ~/.config/nvim/lazy-lock.json into this repo and commit it.
# `sync` would rewrite the lockfile it just read, so the locked path uses
# install + restore instead.
if [ -f "$DOTFILES_DIR/.config/nvim/lazy-lock.json" ]; then
  cp "$DOTFILES_DIR/.config/nvim/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
  NVIM_LAZY_CMD="require('lazy').install({ wait = true, show = false }); require('lazy').restore({ wait = true, show = false })"
  NVIM_LAZY_DESC="plugins pinned to lazy-lock.json"
else
  NVIM_LAZY_CMD="require('lazy').sync({ wait = true, show = false })"
  NVIM_LAZY_DESC="plugins synced (no lockfile — versions will drift)"
fi

if command -v nvim &> /dev/null; then
  nvim --headless -c "lua $NVIM_LAZY_CMD" -c "qa" 2>/dev/null || true
  echo "  Neovim configured ($NVIM_LAZY_DESC)"
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
# Match the line this script actually writes, not the repo's name. Coder clones
# the dotfiles to ~/.config/coderv2/dotfiles, so a guard looking for
# "coder-dotfiles/.zshrc" never matched under Coder's own dotfiles mechanism and
# every re-provision appended another copy — one box had accumulated 14, each one
# re-sourcing this repo's .zshrc on every shell start. -F because $DOTFILES_DIR
# is a path full of dots.
if ! grep -qF "source $DOTFILES_DIR/.zshrc" "$HOME/.zshrc" 2>/dev/null; then
  echo "source $DOTFILES_DIR/.zshrc" >> "$HOME/.zshrc"
  echo "  Added source line to ~/.zshrc"
else
  echo "  ~/.zshrc already sources dotfiles"
fi

# Self-heal a box provisioned before the guard above was fixed: collapse repeats
# of that one exact line, keeping the first. Touches nothing else in ~/.zshrc,
# and leaves a .bak beside it.
ZSHRC_DUPES=$(grep -cxF "source $DOTFILES_DIR/.zshrc" "$HOME/.zshrc" 2>/dev/null) || ZSHRC_DUPES=0
if [ "$ZSHRC_DUPES" -gt 1 ]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
  awk -v line="source $DOTFILES_DIR/.zshrc" \
    '$0 == line { if (seen++) next } { print }' \
    "$HOME/.zshrc.bak" > "$HOME/.zshrc"
  echo "  Removed $((ZSHRC_DUPES - 1)) duplicate source line(s) (backup: ~/.zshrc.bak)"
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
echo "Then install the Claude Code plugins (inside claude, or as 'claude plugin ...'):"
echo "  /plugin marketplace add RoadRunnerEngineering/rr-skills"
echo "  /plugin install typescript-lsp@roadrunner-agent-skills"
echo "  /plugin install ruby-lsp@roadrunner-agent-skills"
echo "  /reload-plugins"
echo ""
echo "Then start your workspace:"
echo "  herdr             # starts the server and restores your last layout"
echo ""
echo "Prefix is Ctrl-Space. Press Ctrl-Space then ? for the full key list."
echo "See CHEATSHEET.md for the workflow."
echo ""
