-- Bytecode cache
if vim.loader then
  vim.loader.enable()
end

-- Disable unused built-in plugins
local disabled_built_ins = {
  'fzf',
  'gzip',
  'matchit',
  'netrwPlugin',
  'matchparen',
  'tarPlugin',
  'tutor',
  'zipPlugin',
  'tohtml'
}
for _, plugin in pairs(disabled_built_ins) do
  vim.g['loaded_' .. plugin] = 1
end

-- UI2
-- https://neovim.io/doc/user/lua/#_ui2
-- o.cmdheight = 0 -- auto hide status line when cmd
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
