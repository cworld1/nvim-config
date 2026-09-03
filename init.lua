-- [Init]
-- require('test.startup-profiler') -- startup test using `PROF=1 nvim`
require('libs.lazy').setup({
  statistic = true,
  trigger_verylazy = true
}) -- statistics must be set before plugins
require('custom.theme').setup() -- theme must be set before plugins

-- [Config]
require('config.startup')
require('config.options')
require('config.keymaps')
require('config.autocmds')

-- [Plugins]
require('plugins.ui')
require('plugins.tool')
local Snacks = require('plugins.snacks')
require('plugins.lsp')
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
require('custom.git').setup({
  get_git_root = Snacks.git.get_root,
  stage = { action = Snacks.picker.actions.git_stage },
  blame = {
    enabled = true,
    msg_template = '   <summary>, <author> (<date>)',
    msg_not_committed = '',
    delay = 1000,
    max_summary_length = 30
  }
})
-- Edit
require('custom.pairs').setup()
require('custom.surround').setup()
require('custom.sudo').setup()
require('custom.md-paste-image').setup({
  img_dir = '_res/%:t:r',
})
