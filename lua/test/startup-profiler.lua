local utils = require('libs.utils')

--[Startup Profiler]
-- Only start when `PROF=1 nvim`
if vim.env.PROF then
  if not utils.is_compatible_version('0.12') then
    vim.notify('Need Neovim 0.12+', vim.log.levels.ERROR)
    return
  end

  vim.cmd('packadd snacks.nvim')
  local profiler = require('snacks.profiler')
  profiler.startup({
    startup = {
      event = 'VimEnter', -- Stop record after startup finished
    },
  })

  -- Keymap
  vim.keymap.set('n', '<leader>pP', function() profiler.toggle() end,
    { desc = 'Toggle profiler' })
  vim.keymap.set('n', '<leader>ps', function() profiler.scratch() end,
    { desc = 'Profiler scratch buffer' })
end
