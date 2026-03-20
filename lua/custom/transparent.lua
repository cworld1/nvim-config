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

M.setup = function(opts)
  opts = opts or {}
  M.config = vim.tbl_extend('force', M.config, opts)
  M.cache_path = vim.fn.stdpath('data') .. package.config:sub(1, 1) .. 'transparent_state'
  M.cache_read() -- load state on startup

  if opts.auto_enable then
    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      callback = function()
        vim.schedule(function() M.toggle(true) end)
      end,
    })
  end
  -- Monitor theme change events to prevent cache pollution
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('TransparentThemeSync', { clear = true }),
    callback = function()
      if vim.g.bg_transparent then
        M.hl_cache = {}
        M.clear()
      end
    end,
  })
end

-- [Cache Module] persist state
M.cache_read = function()
  local ok, data = pcall(vim.fn.readfile, M.cache_path)
  vim.g.bg_transparent = ok and #data > 0 and vim.trim(data[1]) == 'true'
end
M.cache_write = function()
  -- Ensure that the parent directory of the cache file exist
  -- to prevent write crashes due to environment differences
  local dir = vim.fn.fnamemodify(M.cache_path, ':h')
  if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, 'p') end
  vim.fn.writefile({ tostring(vim.g.bg_transparent) }, M.cache_path)
end

-- [Core] Clear highlight groups
M.clear_group = function(group)
  local list = type(group) == 'string' and { group } or group

  for _, g in ipairs(list) do
    if not vim.tbl_contains(M.config.exclude_groups, g) then
      local ok, prev = pcall(vim.api.nvim_get_hl, 0, { name = g, link = false })
      if ok and prev then
        -- Preserve original highlight (only save on first transparency)
        if M.hl_cache[g] == nil then
          M.hl_cache[g] = vim.deepcopy(prev)
        end

        -- Set transparent
        if prev.bg or prev.ctermbg then
          prev.bg, prev.ctermbg = 'NONE', 'NONE'
          vim.api.nvim_set_hl(0, g, prev)
        end
      end
    end
  end
end

M.do_clear = function()
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
  for _, t in ipairs(M.timers) do
    pcall(function()
      if t and not t:is_closing() then t:close() end
    end)
  end
  M.timers = {}

  M.do_clear()

  local timer = vim.uv.new_timer()
  timer:start(800, 0, vim.schedule_wrap(function()
    M.do_clear()
    pcall(function()
      if not timer:is_closing() then timer:close() end
    end)
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

  for _, t in ipairs(M.timers) do
    if t and not t:is_closing() then t:close() end
  end
  M.timers = {}
  -- Restore original highlights
  for group, attrs in pairs(M.hl_cache) do
    vim.api.nvim_set_hl(0, group, attrs)
  end
  -- Clear cache for next save
  M.hl_cache = {}
  -- If the theme plugin reloads the highlight, reset the theme
  if vim.g.colors_name then pcall(vim.cmd.colorscheme, vim.g.colors_name) end
end

function M.toggle(opt)
  if opt ~= nil then
    vim.g.bg_transparent = opt
  else
    vim.g.bg_transparent = not vim.g.bg_transparent
  end
  if vim.g.bg_transparent then
    M.enable()
  else
    M.disable()
  end
end

-- [Commands & Keymaps]
vim.api.nvim_create_user_command('TransparentEnable', M.enable,
  { desc = 'Enable background transparency' })
vim.api.nvim_create_user_command('TransparentDisable', M.disable,
  { desc = 'Disable background transparency' })
vim.api.nvim_create_user_command('TransparentToggle', M.toggle,
  { desc = 'Toggle background transparency' })
vim.keymap.set('n', '<leader>ut', M.toggle, { desc = 'Toggle transparent background' })

return M
