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

if vim.fn.has('nvim-0.12') == 0 then
  vim.notify('Need Neovim 0.12+', vim.log.levels.ERROR)
  return
end
