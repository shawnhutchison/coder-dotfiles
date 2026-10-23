---
name: engage-setup
description: Setup stage of Engage: make this Coder workspace ready for ticket work (the rr-skills marketplace, the LSP plugins and their language servers, and the Jira, GitHub and Datadog MCP tools), then record the result in ~/.claude/tickets/dev-setup.md. Use when the user asks to set up a new or fresh workspace or dev environment for ticket work, or when the engage skill finds Setup missing.
---

# Stage: Setup

Makes this Coder workspace ready for ticket work: the org plugin marketplace, the LSP plugins and their language servers, and the Jira, GitHub and Datadog MCP tools. It runs once per workspace. `~/.claude/tickets/dev-setup.md` records the result.

## 1. Check the marker

Read `~/.claude/tickets/dev-setup.md`. If its `status` is `complete` and its `workspace` equals `$CODER_WORKSPACE_NAME`, print its check table and stop, unless the user asked to run Setup again.

## 2. Preconditions

| Check | Command | If it fails |
|---|---|---|
| GitHub CLI auth | `gh auth status` | Ask the user to run `! gh-auth-refresh`. Coder's GitHub token expires. |
| GitHub SSH host trust | `ssh -o BatchMode=yes -T git@github.com` prints "successfully authenticated" | install.sh adds the host keys. Ask the user to rerun install.sh. |
| Herdr | `test "${HERDR_ENV:-}" = 1` | Not required. Workers then run as Agent subagents. Note it in the marker. |

## 3. Marketplace and LSP plugins

The `claude` CLI is the authority for syntax. If a subcommand below fails, run `claude plugin --help` and use what it lists.

1. `claude plugin marketplace list`. If `roadrunner-agent-skills` is missing, run `claude plugin marketplace add RoadRunnerEngineering/rr-skills`. Otherwise run `claude plugin marketplace update roadrunner-agent-skills`.
2. `claude plugin list`. Install each of these that is missing:
   ```
   claude plugin install typescript-lsp@roadrunner-agent-skills
   claude plugin install ruby-lsp@roadrunner-agent-skills
   claude plugin install pyright-lsp@roadrunner-agent-skills
   claude plugin install terraform-lsp@roadrunner-agent-skills
   claude plugin install rust-analyzer-lsp@roadrunner-agent-skills
   ```
3. If the CLI cannot install them, ask the user to type the same commands as `/plugin marketplace add ...` and `/plugin install ...` in this session.

## 4. Language servers

Each LSP plugin only names a command to start. It installs no binary. Install a server only when a repo under `~/workspace` has files in its language:

```
git -C ~/workspace/<repo> ls-files '*.py' | head -1
```

| Plugin | Binary | Install when missing |
|---|---|---|
| typescript-lsp | `typescript-language-server` | install.sh installs it. Otherwise: `npm install -g --prefix "$HOME/.npm-global" --no-audit --no-fund typescript-language-server typescript` |
| ruby-lsp | `ruby-lsp` | Comes with the image's asdf Ruby at `~/.asdf/shims/ruby-lsp`. Otherwise: `gem install ruby-lsp` |
| pyright-lsp | `pyright-langserver` | `npm install -g --prefix "$HOME/.npm-global" --no-audit --no-fund pyright` |
| terraform-lsp | `terraform-ls` | See below |
| rust-analyzer-lsp | `rust-analyzer` | See below |

Downloaded servers go to `~/.local/bin`, which `.zshrc` puts on PATH. Download into `~/.cache/engage-setup/` and copy with `install -m 0755`, which sets the executable bit.

```
mkdir -p ~/.cache/engage-setup ~/.local/bin
V=$(curl -fsS https://checkpoint-api.hashicorp.com/v1/check/terraform-ls | jq -r .current_version)
curl -fsSL -o ~/.cache/engage-setup/terraform-ls-$V.zip \
  "https://releases.hashicorp.com/terraform-ls/${V}/terraform-ls_${V}_linux_amd64.zip"
unzip -o -d ~/.cache/engage-setup/terraform-ls-$V ~/.cache/engage-setup/terraform-ls-$V.zip
install -m 0755 ~/.cache/engage-setup/terraform-ls-$V/terraform-ls ~/.local/bin/terraform-ls

curl -fsSL https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz \
  | gunzip > ~/.cache/engage-setup/rust-analyzer
install -m 0755 ~/.cache/engage-setup/rust-analyzer ~/.local/bin/rust-analyzer
```

If a download URL fails, find the current release on the project's releases page. Record each server's version with `<binary> --version`.

## 5. MCP tools

The tickets need three tool sets: Jira, GitHub and Datadog. RoadRunner manages MCP access through mintmcp, so a workspace usually has one gateway server that bundles them.

1. Load and find the tools with ToolSearch: `getJiraIssue`, GitHub `get_me`, and a Datadog search tool.
2. Probe each with one small read: Jira `atlassianUserInfo`, GitHub `get_me`, Datadog `search_datadog_monitors` with a narrow query.
3. If a tool set is missing, run `claude mcp list`.
   - A server marked "Needs authentication": ask the user to run `/mcp` and sign in.
   - No server provides the tools: ask the user for their mintmcp gateway URL. Add it with `claude mcp add --transport http --scope user <name> <url>`, then ask the user to run `/mcp` to sign in. Never write the URL into this framework or into a repo.
4. A new server loads in new sessions only. Ask the user to start a new session and run `/engage setup` again to finish the probes.

## 6. Reload and probe the language servers

If this run installed plugins, ask the user to type `/reload-plugins`, and wait for them to confirm. You cannot run slash commands.

Load the LSP tool with ToolSearch (`select:LSP`). For each language with files in the workspace, pick one source file and request its document symbols. Use, for example, a `.ts` file in lyra, a model in coyote, a `.py` file in beeline and a `.tf` file in lyra or cetus.

- A result with symbols is a pass.
- An empty result from TypeScript can mean the server is still indexing. Wait 30 seconds and retry once, then record `indexing` if it is still empty.
- An "Executable not found" error means step 4 missed that server.

## 7. Write the marker

Write `~/.claude/tickets/dev-setup.md` from `~/.claude/skills/engage/templates/dev-setup.md`. Set `status` to `complete` when every check passed or is marked not needed. Otherwise set it to `partial` and list what the user must do. Set `framework` to the short commit of the repo this skill lives in: `git -C "$(dirname "$(readlink -f ~/.claude/skills/engage)")" rev-parse --short HEAD`.

Print the check table.

## Exit

`status: complete` in the marker. Setup needs no "Engage."
