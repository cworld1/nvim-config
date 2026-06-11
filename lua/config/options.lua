local utils = require('libs.utils')
local o = vim.opt

-- Custom
o.shell = 'fish'

-- [Appearance]
if utils.is_compatible_version('0.10') then
  o.termguicolors = true -- enable 24-bit RGB colors
end
-- o.winborder = 'single' -- add a border of ui
-- o.showmode = false -- Hide mode status
-- Line edit
o.cursorline = true -- highlight current line
o.scrolloff = 4 -- keep 4 lines visible around cursor
o.scrolloffpad = 1 -- cursor position stays at middle when you go to eob
o.sidescrolloff = 8 -- keep 8 columns visible horizontally
-- Line number
o.number = true
o.relativenumber = true
-- Indent
o.expandtab = true -- use spaces instead of tabs
o.shiftwidth = 2 -- indent size
o.tabstop = 2 -- tab character width
o.shiftround = true -- round indent to nearest multiple of shiftwidth
o.smartindent = true -- auto-indent new lines intelligently
-- Wrap
-- This will be opened by `config/autocommands` for certain filetypes
o.wrap = false -- default not line wrap
-- o.linebreak = true -- wrap at word boundary if wrap
o.breakindent = true -- maintain indent on wrap
-- Others
o.winminwidth = 5 -- prevent tiny splits

-- [Editor]
o.fileformat = 'unix'
-- o.mouse = 'a' -- enable mouse in all modes (maybe is default to true?)
o.laststatus = 3 -- global satusline (once you add one)
o.colorcolumn = '80' -- column ruler
o.confirm = true -- confirm before quitting unsaved changes
o.signcolumn = 'yes' -- leave the left lsp or git column
o.swapfile = false -- disable swapfile function
-- Case
o.ignorecase = true -- case-insensitive by default
o.incsearch = true -- show search results while typing
o.smartcase = true -- but smart if uppercase is used
-- Split
o.splitbelow = true -- horizontal splits below
o.splitright = true -- vertical splits to the right
o.splitkeep = 'screen' -- preserve layout when splitting
-- Format
o.formatoptions =
'tcqjrlmnt' -- not keep comments, wrap text, autoformat when possible
-- Command
o.inccommand = 'nosplit' -- live preview for :substitute
o.wildmode = 'longest:full,full' -- enhanced command completion
-- Fold https://www.jackfranklin.co.uk/blog/code-folding-in-vim-neovim/
o.foldmethod = 'expr'
-- Fold expr are on `plugins/lsp`
-- o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
o.foldcolumn = '0'
o.foldlevel = 99
o.foldtext = '' -- make fold preview be syntax highlighted
-- o.foldtext = "v:lua.vim.fn.getline(v:foldstart) .. ' …'" -- fold text
o.foldlevelstart = 5
o.foldnestmax = 6 -- levels that won't be broken down into more granular folds
-- Others
o.jumpoptions = 'view' -- restore view after jump
o.virtualedit = 'block' -- allow cursor past EOL in block mode

-- [Functions]
-- Clipboard
o.clipboard = vim.env.SSH_CONNECTION and '' or 'unnamedplus'
-- Check spelling
-- This will be opened by `config/autocommands` for certain filetypes
o.spell = true
o.spelllang = 'en_us,cjk'
o.spellsuggest = 'best,5' -- show only first best 5
-- o.spelloptions = 'underscore'
o.spelloptions = 'camel' --support CamelCase
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
