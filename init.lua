-- [Init]
-- require('test.startup') -- startup test using `PROF=1 nvim`
require('custom.theme').setup() -- theme must be set before plugins

-- [Config]
require('config.options')
require('config.keymaps')
require('config.autocmds')

-- [Plugins]
require('plugins.ui')
require('plugins.lsp')
require('plugins.tool')
local Snacks = require('plugins.snacks')
-- Input method swtich for non-English users
-- require('plugins.im-select')

-- [Custom]
-- UI
require('custom.transparent').setup({ auto_enable = true })
-- Tools
local icons = require('libs.icons')
require('custom.tabline').setup({
  hide_single_tab = true,
  on_close = function(buf_id) Snacks.bufdelete(buf_id, { wipe = true }) end,
  file_icons = function(name) return Snacks.util.icon(name, 'file') end,
  icons = { close = icons.basic.close, modify = icons.basic.modify }
})
require('custom.statusline').setup({
  git_cache_setup = { get_git_root = Snacks.git.get_root },
  hide_filename_by_ft = { snacks_picker_list = true },
  icons = { branch = icons.git.branch }
})
-- Edit
require('custom.pairs').setup()
require('custom.surround').setup()
require('custom.sudo').setup()

-- Trigger VeryLazy event after all are loaded
require('libs.lazy').trigger_verylazy()
