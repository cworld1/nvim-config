local utils = require('libs.utils')

-- Custom
vim.opt.shell = 'fish'

-- [Appearance]
if utils.is_compatible_version('0.10') then
  vim.opt.termguicolors = true -- enable 24-bit RGB colors
end
-- vim.opt.winborder = 'single' -- add a border of ui
-- vim.opt.showmode = false -- Hide mode status
-- Line edit
vim.opt.cursorline = true -- highlight current line
vim.opt.scrolloff = 4 -- keep 4 lines visible around cursor
vim.opt.scrolloffpad = 1 -- cursor position stays at middle when you go to eob
vim.opt.sidescrolloff = 8 -- keep 8 columns visible horizontally
-- Line number
vim.opt.number = true
vim.opt.relativenumber = true
-- Indent
vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.shiftwidth = 2 -- indent size
vim.opt.tabstop = 2 -- tab character width
vim.opt.shiftround = true -- round indent to nearest multiple of shiftwidth
vim.opt.smartindent = true -- auto-indent new lines intelligently
-- Wrap
-- This will be opened by `config/autocommands` for certain filetypes
vim.opt.wrap = false -- default not line wrap
-- vim.opt.linebreak = true -- wrap at word boundary if wrap
vim.opt.breakindent = true -- maintain indent on wrap
-- Others
vim.opt.winminwidth = 5 -- prevent tiny splits

-- [Editor]
vim.opt.fileformat = 'unix'
-- vim.opt.mouse = 'a' -- enable mouse in all modes (maybe is default to true?)
vim.opt.laststatus = 3 -- global satusline (once you add one)
vim.opt.colorcolumn = '80' -- column ruler
vim.opt.confirm = true -- confirm before quitting unsaved changes
vim.opt.signcolumn = 'yes' -- leave the left lsp or git column
vim.opt.swapfile = false -- disable swapfile function
-- Case
vim.opt.ignorecase = true -- case-insensitive by default
vim.opt.incsearch = true -- show search results while typing
vim.opt.smartcase = true -- but smart if uppercase is used
-- Split
vim.opt.splitbelow = true -- horizontal splits below
vim.opt.splitright = true -- vertical splits to the right
vim.opt.splitkeep = 'screen' -- preserve layout when splitting
-- Format
vim.opt.formatoptions =
'tcqjrlmnt' -- not keep comments, wrap text, autoformat when possible
-- Command
vim.opt.inccommand = 'nosplit' -- live preview for :substitute
vim.opt.wildmode = 'longest:full,full' -- enhanced command completion
-- Fold https://www.jackfranklin.co.uk/blog/code-folding-in-vim-neovim/
vim.opt.foldmethod = 'expr'
-- Fold expr are on `plugins/lsp`
-- vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldcolumn = '0'
vim.opt.foldlevel = 99
vim.opt.foldtext = '' -- make fold preview be syntax highlighted
-- vim.opt.foldtext = "v:lua.vim.fn.getline(v:foldstart) .. ' …'" -- fold text
vim.opt.foldlevelstart = 5
vim.opt.foldnestmax = 6 -- levels that won't be broken down into more granular folds
-- Others
vim.opt.jumpoptions = 'view' -- restore view after jump
vim.opt.virtualedit = 'block' -- allow cursor past EOL in block mode

-- [Functions]
-- Clipboard
vim.opt.clipboard = vim.env.SSH_CONNECTION and '' or 'unnamedplus'
-- Check spelling
-- This will be opened by `config/autocommands` for certain filetypes
vim.opt.spell = false
vim.opt.spelllang = 'en_us,cjk'
vim.opt.spellsuggest = 'best,5' -- show only first best 5
-- vim.opt.spelloptions = 'underscore'
vim.opt.spelloptions = 'camel' --support CamelCase
-- UI2
-- https://neovim.io/doc/user/lua/#_ui2
-- vim.opt.cmdheight = 0 -- auto hide status line when cmd
local ok, ui2 = pcall(require, 'vim._core.ui2')
if ok then
  ui2.enable({
    enable = true,
    msg = {
      -- targets = 'msg',
      -- cmd = { height = 0.5, },
      -- msg = { height = 0.5, timeout = 4000, },
      -- dialog = { height = 0.5, },
      -- pager = { height = 1, },
    },
  })
end
