-- Transparent background
-- https://github.com/xiyaowong/transparent.nvim/blob/main/lua/transparent/init.lua

local M = {
  hl_cache = {},
  timers = {}
}

-- Config Module
M.config = {
  groups = {
    'Normal', 'NormalNC', 'SignColumn', 'EndOfBuffer',
    'LineNr', 'CursorLineNr', 'NonText',
    'Comment', 'Constant', 'Special', 'Identifier', 'Statement',
    'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
    'Conditional', 'Repeat', 'Operator', 'Structure',
    -- Append from the origin list
    'Folded', -- Fold text
  },

  extra_groups = {
    -- Snacks
    'SnacksNormalNC', 'SnacksNormal',
    'SnacksPicker', 'SnacksPickerBorder',
    'SnacksPickerBox', 'SnacksPickerBoxBorder',
    'SnacksPickerList', 'SnacksPickerListBorder',
    'SnacksPickerInput', 'SnacksPickerInputBorder',
    'SnacksPickerPreview', 'SnacksPickerPreviewBorder',
  },

  exclude_groups = {},
  on_clear = function() end,
}

function M.setup(opts)
  M.config = vim.tbl_extend('force', M.config, opts)
  M.cache_path = vim.fn.stdpath('data') .. package.config:sub(1, 1) .. 'transparent_state'

  M.cache_read() -- load state on startup

  if opts.auto_enable ~= nil then
    if opts.auto_enable then
      vim.g.bg_transparent = true
    else
      vim.g.bg_transparent = false
    end
    M.cache_write()
  end

  vim.schedule(function()
    if vim.g.bg_transparent then
      M.clear()
    else
      M.disable()
    end
  end)

  -- Monitor theme change events to prevent cache pollution
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('TransparentThemeSync', { clear = true }),
    callback = function()
      if vim.g.bg_transparent then
        M.hl_cache = {}
        M.clear()
      else
        M.hl_cache = {}
      end
    end,
  })

  -- [Commands & Keymaps]
  vim.api.nvim_create_user_command('TransparentEnable', M.enable,
    { desc = 'Enable background transparency' })
  vim.api.nvim_create_user_command('TransparentDisable', M.disable,
    { desc = 'Disable background transparency' })
  vim.api.nvim_create_user_command('TransparentToggle', M.toggle,
    { desc = 'Toggle background transparency' })
  vim.keymap.set('n', '<leader>ut', M.toggle, { desc = 'Toggle transparent background' })
end

-- [Cache Module] persist state
function M.cache_read()
  local stat = vim.uv.fs_stat(M.cache_path)
  if stat then
    local fd = vim.uv.fs_open(M.cache_path, 'r', 438)
    if fd then
      local data = vim.uv.fs_read(fd, stat.size, 0)
      vim.uv.fs_close(fd)
      if data then
        vim.g.bg_transparent = (data:match('true') ~= nil)
        return
      end
    end
  end
  vim.g.bg_transparent = false
end

function M.cache_write()
  local dir = vim.fs.dirname(M.cache_path)
  if not vim.uv.fs_stat(dir) then vim.fs.mkdir(dir, { parents = true }) end
  local fd = vim.uv.fs_open(M.cache_path, 'w', 438)
  if fd then
    vim.uv.fs_write(fd, tostring(vim.g.bg_transparent), -1)
    vim.uv.fs_close(fd)
  end
end

-- [Core] Clear highlight groups
function M.clear_group(group)
  local list = type(group) == 'string' and { group } or group

  for i = 1, #list do
    local g = list[i]
    if not M.config.exclude_groups[g] then
      local def = vim.api.nvim_get_hl(0, { name = g, link = true })

      if def and not def.link then
        if M.hl_cache[g] == nil then
          M.hl_cache[g] = vim.deepcopy(def)
        end

        if def.bg or def.ctermbg then
          def.bg = nil
          def.ctermbg = nil
          vim.api.nvim_set_hl(0, g, def)
        end
      end
    end
  end
end

function M.do_clear()
  if not vim.g.bg_transparent then return end

  M.clear_group(M.config.groups)
  M.clear_group(M.config.extra_groups)

  if type(vim.g.transparent_groups) == 'table' then
    M.clear_group(vim.g.transparent_groups)
  end
end

function M.clear()
  if not vim.g.bg_transparent then return end

  -- Use pcall to suppress underlying pointer errors
  for i = 1, #M.timers do
    require('snacks').util.stop(M.timers[i])
  end
  M.timers = {}

  M.do_clear()

  local timer = vim.uv.new_timer()
  timer:start(800, 0, vim.schedule_wrap(function()
    M.do_clear()
    require('snacks').util.stop(timer)
  end))
  table.insert(M.timers, timer)

  vim.api.nvim_exec_autocmds('User', { pattern = 'TransparentClear', modeline = false })
  M.config.on_clear()
end

-- [Public API]
function M.enable()
  vim.g.bg_transparent = true
  M.cache_write()
  M.clear()
end

function M.disable()
  vim.g.bg_transparent = false
  M.cache_write()

  for i = 1, #M.timers do
    require('snacks').util.stop(M.timers[i])
  end
  M.timers = {}
  -- Restore original highlights
  for group, attrs in pairs(M.hl_cache) do
    vim.api.nvim_set_hl(0, group, attrs)
  end
  -- Clear cache for next save
  M.hl_cache = {}
  -- If the theme plugin reloads the highlight, reset the theme
  vim.cmd('redraw!')
end

function M.toggle(opt)
  vim.g.bg_transparent = opt ~= nil and opt or not vim.g.bg_transparent
  if vim.g.bg_transparent then M.enable() else M.disable() end
end

return M
