local utils = require('libs.utils')

--[Startup Profiler]
-- Only start when `PROF=1 nvim`
if vim.env.PROF then
  vim.cmd('packadd snacks.nvim')
  require('snacks.profiler').startup({
    startup = {
      event = 'VimEnter', -- Stop record after startup finished
    },
  })
end

if utils.is_compatible_version('0.12') then
  vim.notify('Need Neovim 0.12+', vim.log.levels.ERROR)
  return
end
