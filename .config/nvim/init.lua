-- ============================================================================
-- Neovim config — lean file navigator for the Herdr + Claude Code workflow.
-- Theme: Tokyo Night *Storm*. Keep the `style` below in sync with the pinned
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
      require("tokyonight").setup({ style = "storm" }) -- storm | moon | night | day
      vim.cmd.colorscheme("tokyonight")
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
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- classic .configs API; the new `main` branch dropped it
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "lua", "vim", "vimdoc", "json", "yaml", "toml",
          "markdown", "markdown_inline", "python", "javascript",
          "typescript", "tsx", "go", "rust", "html", "css",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
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
