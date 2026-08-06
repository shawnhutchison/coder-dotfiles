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
  -- "BUILD SOMETHING" in a big figlet font, each letter a different Tokyo Night
  -- accent. The header art + per-line color map are generated (figlet -f big);
  -- to change the words, regenerate both tables together — the column ranges in
  -- header_hl must line up with the glyphs in header_lines.
  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VimEnter",
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      local header_lines = {
        " ____    _    _   _____   _        _____   ",
        "|  _ \\  | |  | | |_   _| | |      |  __ \\  ",
        "| |_) | | |  | |   | |   | |      | |  | | ",
        "|  _ <  | |  | |   | |   | |      | |  | | ",
        "| |_) | | |__| |  _| |_  | |____  | |__| | ",
        "|____/   \\____/  |_____| |______| |_____/  ",
        "",
        "  _____    ____    __  __   ______   _______   _    _   _____   _   _    _____  ",
        " / ____|  / __ \\  |  \\/  | |  ____| |__   __| | |  | | |_   _| | \\ | |  / ____| ",
        "| (___   | |  | | | \\  / | | |__       | |    | |__| |   | |   |  \\| | | |  __  ",
        " \\___ \\  | |  | | | |\\/| | |  __|      | |    |  __  |   | |   | . ` | | | |_ | ",
        " ____) | | |__| | | |  | | | |____     | |    | |  | |  _| |_  | |\\  | | |__| | ",
        "|_____/   \\____/  |_|  |_| |______|    |_|    |_|  |_| |_____| |_| \\_|  \\_____| ",
      }
      local header_hl = {
        { { "TokBlue", 0, 7 }, { "TokMauve", 8, 16 }, { "TokGreen", 17, 24 }, { "TokYellow", 25, 33 }, { "TokRed", 34, 42 } },
        { { "TokBlue", 0, 7 }, { "TokMauve", 8, 16 }, { "TokGreen", 17, 24 }, { "TokYellow", 25, 33 }, { "TokRed", 34, 42 } },
        { { "TokBlue", 0, 7 }, { "TokMauve", 8, 16 }, { "TokGreen", 17, 24 }, { "TokYellow", 25, 33 }, { "TokRed", 34, 42 } },
        { { "TokBlue", 0, 7 }, { "TokMauve", 8, 16 }, { "TokGreen", 17, 24 }, { "TokYellow", 25, 33 }, { "TokRed", 34, 42 } },
        { { "TokBlue", 0, 7 }, { "TokMauve", 8, 16 }, { "TokGreen", 17, 24 }, { "TokYellow", 25, 33 }, { "TokRed", 34, 42 } },
        { { "TokBlue", 0, 7 }, { "TokMauve", 8, 16 }, { "TokGreen", 17, 24 }, { "TokYellow", 25, 33 }, { "TokRed", 34, 42 } },
        {},
        { { "TokTeal", 0, 8 }, { "TokCyan", 9, 17 }, { "TokPeach", 18, 26 }, { "TokBlue", 27, 35 }, { "TokMauve", 36, 45 }, { "TokGreen", 46, 54 }, { "TokYellow", 55, 62 }, { "TokRed", 63, 70 }, { "TokTeal", 71, 79 } },
        { { "TokTeal", 0, 8 }, { "TokCyan", 9, 17 }, { "TokPeach", 18, 26 }, { "TokBlue", 27, 35 }, { "TokMauve", 36, 45 }, { "TokGreen", 46, 54 }, { "TokYellow", 55, 62 }, { "TokRed", 63, 70 }, { "TokTeal", 71, 79 } },
        { { "TokTeal", 0, 8 }, { "TokCyan", 9, 17 }, { "TokPeach", 18, 26 }, { "TokBlue", 27, 35 }, { "TokMauve", 36, 45 }, { "TokGreen", 46, 54 }, { "TokYellow", 55, 62 }, { "TokRed", 63, 70 }, { "TokTeal", 71, 79 } },
        { { "TokTeal", 0, 8 }, { "TokCyan", 9, 17 }, { "TokPeach", 18, 26 }, { "TokBlue", 27, 35 }, { "TokMauve", 36, 45 }, { "TokGreen", 46, 54 }, { "TokYellow", 55, 62 }, { "TokRed", 63, 70 }, { "TokTeal", 71, 79 } },
        { { "TokTeal", 0, 8 }, { "TokCyan", 9, 17 }, { "TokPeach", 18, 26 }, { "TokBlue", 27, 35 }, { "TokMauve", 36, 45 }, { "TokGreen", 46, 54 }, { "TokYellow", 55, 62 }, { "TokRed", 63, 70 }, { "TokTeal", 71, 79 } },
        { { "TokTeal", 0, 8 }, { "TokCyan", 9, 17 }, { "TokPeach", 18, 26 }, { "TokBlue", 27, 35 }, { "TokMauve", 36, 45 }, { "TokGreen", 46, 54 }, { "TokYellow", 55, 62 }, { "TokRed", 63, 70 }, { "TokTeal", 71, 79 } },
      }
      -- Palette pulled straight from Tokyo Night Night. Defined as standalone
      -- groups (not linked to theme groups) so the colors are exact, and
      -- re-applied on ColorScheme since a theme switch clears user highlights.
      local palette = {
        { "TokBlue", "#7aa2f7" },
        { "TokMauve", "#bb9af7" },
        { "TokGreen", "#9ece6a" },
        { "TokYellow", "#e0af68" },
        { "TokRed", "#f7768e" },
        { "TokTeal", "#73daca" },
        { "TokCyan", "#7dcfff" },
        { "TokPeach", "#ff9e64" },
      }
      local function set_palette_hl()
        for _, c in ipairs(palette) do
          vim.api.nvim_set_hl(0, c[1], { fg = c[2], bold = true })
        end
      end
      set_palette_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_palette_hl })

      dashboard.section.header.val = header_lines
      dashboard.section.header.opts.hl = header_hl

      -- Plain-text buttons (no Nerd Font glyphs — none is installed yet).
      dashboard.section.buttons.val = {
        dashboard.button("f", "Find file",     "<cmd>Telescope find_files<CR>"),
        dashboard.button("r", "Recent files",  "<cmd>Telescope oldfiles<CR>"),
        dashboard.button("g", "Grep project",  "<cmd>Telescope live_grep<CR>"),
        dashboard.button("e", "File explorer", "<cmd>Neotree toggle<CR>"),
        dashboard.button("q", "Quit",          "<cmd>qa<CR>"),
      }
      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "TokBlue"
        button.opts.hl_shortcut = "TokYellow"
      end

      dashboard.section.footer.val = "build something"
      dashboard.section.footer.opts.hl = "TokMauve"

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
