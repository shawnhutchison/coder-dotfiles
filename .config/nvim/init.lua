-- ============================================================================
-- Neovim config — lean file navigator for the Herdr + Claude Code workflow.
-- Theme: Tokyo Night *Night*. Keep the `style` below in sync with the pinned
-- [theme.custom] block in .config/herdr/config.toml so both sides match.
-- Plugins managed by lazy.nvim (auto-bootstraps).
-- ============================================================================

-- Leader must be set before lazy loads so plugin mappings pick it up.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
local opt = vim.opt
opt.number = true              -- absolute line numbers
opt.relativenumber = true      -- relative numbers for fast motions
opt.mouse = "a"                -- mouse in all modes (handy under Ghostty)
opt.clipboard = "unnamedplus"  -- use the system clipboard
opt.termguicolors = true       -- 24-bit color (true color)
opt.signcolumn = "yes"         -- always show the sign column (no text shift)
opt.cursorline = true          -- highlight the current line
opt.scrolloff = 8              -- keep context around the cursor
opt.wrap = false

opt.ignorecase = true          -- case-insensitive search...
opt.smartcase = true           -- ...unless the query has capitals
opt.incsearch = true
opt.hlsearch = true

opt.expandtab = true           -- spaces, not tabs
opt.tabstop = 2
opt.shiftwidth = 2
opt.smartindent = true

opt.splitright = true          -- new splits open right / below
opt.splitbelow = true
opt.undofile = true            -- persistent undo across sessions
opt.updatetime = 250
opt.timeoutlen = 400           -- which-key popup delay

-- ---------------------------------------------------------------------------
-- System clipboard over OSC 52
-- ---------------------------------------------------------------------------
-- On a headless Coder box there is no clipboard provider, so a plain yank with
-- `unnamedplus` reaches nothing. OSC 52 makes Neovim *encode* the yank into a
-- terminal escape that rides through Herdr out to Ghostty, which writes the Mac
-- clipboard. Copy only: terminals refuse OSC 52 *reads* for security, so paste
-- comes from Neovim's own registers (a terminal round-trip on every paste would
-- otherwise stall the pane). Needs `clipboard-write = allow` in the Ghostty
-- config. Guarded so a pre-0.10 Neovim (no osc52 module) still loads.
local ok_osc52, osc52 = pcall(require, "vim.ui.clipboard.osc52")
if ok_osc52 then
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "osc52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

-- ---------------------------------------------------------------------------
-- Core keymaps (plugin-specific maps live with their plugins below)
-- ---------------------------------------------------------------------------
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
-- Move between windows with Ctrl + h/j/k/l. These stay Neovim-only: Herdr has
-- no vim-tmux-navigator equivalent, so pane movement lives on Ctrl+Alt+h/j/k/l
-- (or prefix h/j/k/l) instead. No collision, nothing to arbitrate.
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- ---------------------------------------------------------------------------
-- Bootstrap lazy.nvim
-- ---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
opt.rtp:prepend(lazypath)

-- ---------------------------------------------------------------------------
-- Plugins
-- ---------------------------------------------------------------------------
require("lazy").setup({
  -- Theme -------------------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    lazy = false,    -- load during startup
    priority = 1000, -- before other plugins so colors apply first
    config = function()
      -- night (#1a1b26) is the darkest variant; storm (#24283b) reads blue next
      -- to Ghostty and Herdr. Keep this in sync with [theme.custom] in
      -- .config/herdr/config.toml and local/ghostty/config.
      require("tokyonight").setup({ style = "night" }) -- storm | moon | night | day
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Start screen ------------------------------------------------------------
  -- "BUILD SOMETHING" in figlet's ANSI Shadow, all Tokyo Night mauve, centered
  -- in the window. BUILD is pre-padded so it sits centered over the wider
  -- SOMETHING: alpha left-pads the whole header block by its longest line, it
  -- does not center the two words independently. Regenerate the art with
  -- `figlet -f "ANSI Shadow" BUILD` / `... SOMETHING` (the font is not one
  -- figlet ships by default — grab "ANSI Shadow.flf" and pass `-d <dir>`).
  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VimEnter",
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      local header_lines = {
        "                   ██████╗ ██╗   ██╗██╗██╗     ██████╗ ",
        "                   ██╔══██╗██║   ██║██║██║     ██╔══██╗",
        "                   ██████╔╝██║   ██║██║██║     ██║  ██║",
        "                   ██╔══██╗██║   ██║██║██║     ██║  ██║",
        "                   ██████╔╝╚██████╔╝██║███████╗██████╔╝",
        "                   ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚═════╝ ",
        "",
        "███████╗ ██████╗ ███╗   ███╗███████╗████████╗██╗  ██╗██╗███╗   ██╗ ██████╗ ",
        "██╔════╝██╔═══██╗████╗ ████║██╔════╝╚══██╔══╝██║  ██║██║████╗  ██║██╔════╝ ",
        "███████╗██║   ██║██╔████╔██║█████╗     ██║   ███████║██║██╔██╗ ██║██║  ███╗",
        "╚════██║██║   ██║██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║██║╚██╗██║██║   ██║",
        "███████║╚██████╔╝██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██║██║ ╚████║╚██████╔╝",
        "╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ",
      }

      -- Mauve for the header + footer, blue for the action buttons. Standalone
      -- groups (exact hexes), re-applied on ColorScheme since a theme switch
      -- clears user highlights.
      local palette = {
        { "TokMauve", "#bb9af7" },
        { "TokBlue", "#7aa2f7" },
      }
      local function set_palette_hl()
        for _, c in ipairs(palette) do
          vim.api.nvim_set_hl(0, c[1], { fg = c[2], bold = true })
        end
      end
      set_palette_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_palette_hl })

      dashboard.section.header.val = header_lines
      dashboard.section.header.opts.hl = "TokMauve"

      dashboard.section.buttons.val = {
        dashboard.button("f", "Find file",     "<cmd>Telescope find_files<CR>"),
        dashboard.button("r", "Recent files",  "<cmd>Telescope oldfiles<CR>"),
        dashboard.button("g", "Grep project",  "<cmd>Telescope live_grep<CR>"),
        dashboard.button("e", "File explorer", "<cmd>Neotree toggle<CR>"),
        dashboard.button("q", "Quit",          "<cmd>qa<CR>"),
      }
      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "TokBlue"
        button.opts.hl_shortcut = "TokMauve"
      end

      dashboard.section.footer.val = "build something"
      dashboard.section.footer.opts.hl = "TokMauve"

      -- Center vertically. The top padding is a *function*, so alpha
      -- re-evaluates it on every draw (it tracks window resizes): half the
      -- height left over above the fixed content block below.
      local n_buttons = #dashboard.section.buttons.val
      local content_height = #header_lines + 2 + (2 * n_buttons - 1) + 1 + 1
      dashboard.opts.layout = {
        {
          type = "padding",
          val = function()
            return math.max(0, math.floor((vim.api.nvim_win_get_height(0) - content_height) / 2))
          end,
        },
        dashboard.section.header,
        { type = "padding", val = 2 },
        dashboard.section.buttons,
        { type = "padding", val = 1 },
        dashboard.section.footer,
      }

      alpha.setup(dashboard.opts)
    end,
  },

  -- Fuzzy finder ------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Native fzf sorter for speed (compiled with `make`).
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = { layout_strategy = "flex" },
      })
      pcall(telescope.load_extension, "fzf")

      local builtin = require("telescope.builtin")
      map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      map("n", "<leader>fg", builtin.live_grep, { desc = "Grep in project" })
      map("n", "<leader>fb", builtin.buffers, { desc = "Open buffers" })
      map("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
      map("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
      map("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Search in buffer" })
      map("n", "<leader><space>", builtin.find_files, { desc = "Find files" })
    end,
  },

  -- File explorer sidebar ---------------------------------------------------
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- icons (needs a Nerd Font in your terminal)
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        filesystem = {
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
          filtered_items = { hide_dotfiles = false, hide_gitignored = false },
        },
        window = { width = 32 },
      })
      map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })
      map("n", "<leader>o", "<cmd>Neotree focus<CR>", { desc = "Focus file explorer" })
    end,
  },

  -- Syntax highlighting / parsing ------------------------------------------
  -- On the `main` branch. This used to pin `branch = "master"` for the classic
  -- `nvim-treesitter.configs` API, but master is frozen upstream and on Neovim
  -- 0.12 it throws inside the injection-query path on every file open:
  --
  --   vim.schedule callback: .../treesitter/languagetree.lua:215:
  --   .../treesitter.lua:197: attempt to call method 'range' (a nil value)
  --
  -- Nothing in this repo changed to cause that — install.sh installs Neovim
  -- from `releases/latest`, so the runtime moved out from under the pin. The
  -- fix is to follow the plugin forward rather than freeze the runtime, since
  -- `main` tracks Neovim's leading edge (it requires 0.12+).
  --
  -- `main` has no module system, so this looks different from the old block:
  -- no `highlight`/`indent` tables, no `ensure_installed`, no `auto_install`.
  -- Parsers are installed explicitly and highlighting is Neovim's own
  -- `vim.treesitter.start()`. It builds parsers with the tree-sitter CLI
  -- (>= 0.26.1) and a C compiler — install.sh puts both on PATH.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,      -- the FileType autocmd below has to be registered before
                       -- the first buffer loads, or that buffer gets no parser
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})

      -- `main` dropped auto_install: a language missing from this list gets no
      -- treesitter highlighting at all, ever. Add languages here rather than
      -- expecting them on demand. install() is async and skips parsers that are
      -- already present, so it costs nothing on later starts.
      pcall(function()
        require("nvim-treesitter").install({
          "bash", "lua", "vim", "vimdoc", "json", "yaml", "toml",
          "markdown", "markdown_inline", "python", "javascript",
          "typescript", "tsx", "go", "rust", "html", "css",
        })
      end)

      -- Highlighting is per-buffer opt-in now. pcall'd because a filetype whose
      -- parser isn't installed (or hasn't finished installing) would otherwise
      -- raise on every file open — the exact failure this migration is fixing.
      -- The treesitter indentexpr is only wired where a parser actually started;
      -- `smartindent` (set at the top of this file) covers everything else.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(ev)
          if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- Statusline --------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({ options = { theme = "tokyonight", globalstatus = true } })
    end,
  },

  -- Git change signs in the gutter -----------------------------------------
  { "lewis6991/gitsigns.nvim", config = true },

  -- Comment toggling: gcc (line), gc (visual) -------------------------------
  { "numToStr/Comment.nvim", config = true },

  -- Keybinding hints popup --------------------------------------------------
  { "folke/which-key.nvim", event = "VeryLazy", config = true },
}, {
  ui = { border = "rounded" },
  checker = { enabled = false },
})
