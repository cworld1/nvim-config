-- Simple Tabline with icons, LSP diagnostics, and close button
-- https://github.com/akinsho/bufferline.nvim/blob/main/doc/bufferline.txt
local icons = require('libs.icons')
local M = {}

-- Default config
M.config = {
  -- Hide tabline when only one buffer is open
  hide_single_tab = false,
  -- on_close: optional function(buf_id) -> boolean
  -- If provided, it's called when a close is requested. If it returns true,
  -- the module will NOT perform the default `bdelete`. If it returns false/nil,
  -- the module will run the default `bdelete <buf_id>`.
  on_close = nil,
  -- icons: function(filename) -> string, string
  ---@diagnostic disable-next-line: unused-local
  file_icons = function(filename)
    local ok, mini_icons = pcall(require, 'mini.icons')
    if ok then
      local icon, hl, _ = mini_icons.get('file', filename)
      return icon or '', hl or 'Normal'
    end
    return '', 'Normal'
  end,
  icons = { close = '󰅖', modify = '●' },
  -- optional name for close highlight group
  close_hl = 'TablineClose',
}

-- Public: programmatic close helper (respects on_close)
M.viewport_start = 1
M.close_buffer = function(buf_id)
  if type(M.config.on_close) == 'function' then
    if M.config.on_close(buf_id) then return end
  end
  pcall(vim.api.nvim_buf_delete, buf_id, { force = false })
end

M.hl_cache = {}
local function get_dynamic_hl(fg_color, bg_hl, bold)
  local cache_key = (fg_color or 'none') .. '_' .. bg_hl .. '_' .. tostring(bold)
  if M.hl_cache[cache_key] then return M.hl_cache[cache_key] end

  local fg_val
  if fg_color and fg_color:sub(1, 1) == '#' then
    fg_val = fg_color
  elseif fg_color then
    local ok, hl_def = pcall(vim.api.nvim_get_hl, 0, { name = fg_color, link = false })
    if ok and hl_def.fg then fg_val = string.format('#%06x', hl_def.fg) end
  end

  local bg_val
  local ok, bg_def = pcall(vim.api.nvim_get_hl, 0, { name = bg_hl, link = false })
  if ok and bg_def.bg then bg_val = string.format('#%06x', bg_def.bg) end

  local new_hl_name = 'TablineDyn_' .. cache_key:gsub('#', ''):gsub(' ', '')
  vim.api.nvim_set_hl(0, new_hl_name, { fg = fg_val, bg = bg_val, bold = bold })

  M.hl_cache[cache_key] = new_hl_name
  return new_hl_name
end

M.setup = function(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  -- Set initial show tabline value
  _G.SimpleTabline = M
  -- v:lua click handlers
  ---@diagnostic disable-next-line: unused-local
  _G.SimpleTablineSwitch = function(buf_id, clicks, button, mods)
    if button == 'l' then
      vim.api.nvim_set_current_buf(buf_id)
    elseif button == 'r' then
      _G.SimpleTabline.close_buffer(buf_id)
    end
  end
  ---@diagnostic disable-next-line: unused-local
  _G.SimpleTablineClose = function(buf_id, clicks, button, mods)
    _G.SimpleTabline.close_buffer(buf_id)
  end

  if M.config.hide_single_tab then M.update_showtabline() else vim.o.showtabline = 2 end
  vim.o.tabline = '%! v:lua.SimpleTabline.render()'

  M.create_highlights()
  local group = vim.api.nvim_create_augroup('SimpleTabline', { clear = true })
  vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = M.create_highlights })
  -- Update showtabline when buffers change
  if M.config.hide_single_tab then
    vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'BufWipeout' }, {
      group = group, callback = function() M.update_showtabline() end,
    })
  end
end

-- Update showtabline option based on buffer count
M.update_showtabline = function()
  local count = 0
  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf_id].buflisted then
      count = count + 1
      if count > 1 then break end
    end
  end
  vim.o.showtabline = count > 1 and 2 or 0
end

-- Create highlight groups
M.create_highlights = function()
  M.hl_cache = {}
  vim.api.nvim_set_hl(0, 'TablineCurrent', { link = 'TabLineSel', bold = true, default = true })
  vim.api.nvim_set_hl(0, 'TablineHidden', { link = 'TabLine', default = true })
  vim.api.nvim_set_hl(0, 'TablineFill', { link = 'TabLineFill', default = true })
end

-- Get LSP diagnostics for buffer
M.get_diagnostics = function(buf_id)
  local counts = { error = 0, warn = 0, info = 0, hint = 0 }
  if vim.diagnostic.count then
    local d = vim.diagnostic.count(buf_id)
    counts.error = d[vim.diagnostic.severity.ERROR] or 0
    counts.warn = d[vim.diagnostic.severity.WARN] or 0
    counts.info = d[vim.diagnostic.severity.INFO] or 0
    counts.hint = d[vim.diagnostic.severity.HINT] or 0
  else
    for _, diagnostic in ipairs(vim.diagnostic.get(buf_id)) do
      local s = diagnostic.severity
      if s == vim.diagnostic.severity.ERROR then
        counts.error = counts.error + 1
      elseif s == vim.diagnostic.severity.WARN then
        counts.warn = counts.warn + 1
      elseif s == vim.diagnostic.severity.INFO then
        counts.info = counts.info + 1
      elseif s == vim.diagnostic.severity.HINT then
        counts.hint = counts.hint + 1
      end
    end
  end
  return counts
end

M.format_tab = function(buf_id, is_current)
  -- Get buffer name
  local bufname = vim.api.nvim_buf_get_name(buf_id)
  local filename = bufname ~= '' and vim.fn.fnamemodify(bufname, ':t') or '[No Name]'

  local bg_hl = is_current and 'TablineCurrent' or 'TablineHidden'
  local tab_hl = '%#' .. bg_hl .. '#'

  local icon, icon_group = M.config.file_icons(filename)
  local icon_hl = get_dynamic_hl(icon_group or 'Normal', bg_hl, false)
  local icon_str = '%#' .. icon_hl .. '# ' .. icon .. ' '

  local diag = M.get_diagnostics(buf_id)
  local diag_str = ''
  if diag.error > 0 then
    local err_hl = get_dynamic_hl('#ED8796', bg_hl, true)
    diag_str = diag_str .. '%#' .. err_hl .. '#' .. icons.lsp.error .. diag.error .. ' '
  end
  if diag.warn > 0 then
    local warn_hl = get_dynamic_hl('#EED49F', bg_hl, true)
    diag_str = diag_str .. '%#' .. warn_hl .. '#' .. icons.lsp.warn .. diag.warn .. ' '
  end

  local is_modified = vim.bo[buf_id].modified
  local close_icon = is_modified and M.config.icons.modify or M.config.icons.close
  local btn_hl = bg_hl

  local switch = '%' .. buf_id .. '@v:lua.SimpleTablineSwitch@'
  local close = '%' .. buf_id .. '@v:lua.SimpleTablineClose@'

  local close_btn = '%#' .. btn_hl .. '#' .. close .. close_icon .. '%X '

  return tab_hl .. switch .. icon_str .. tab_hl .. filename .. ' ' .. diag_str .. close_btn
end

-- Render tabline
M.render = function()
  local tabs = {}
  local current = vim.api.nvim_get_current_buf()
  local current_idx = 0
  local sep_str = '%#TablineFill#|'
  local sep_width = 3

  -- Get all tabs & calculate text width
  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf_id].buflisted then
      local is_current = (buf_id == current)
      local str = M.format_tab(buf_id, is_current)

      local clean_str = str:gsub('%%#.-#', ''):gsub('%%%d+@.-@', ''):gsub('%%X', '')
      local width = vim.fn.strdisplaywidth(clean_str)

      table.insert(tabs, { str = str, width = width })
      if is_current then current_idx = #tabs end
    end
  end

  if #tabs == 0 then return '' end
  if current_idx == 0 then current_idx = M.viewport_start end

  -- Verify window width
  if current_idx < M.viewport_start then
    M.viewport_start = current_idx
  end

  local max_width = vim.o.columns
  local left_ind = '%#TablineHidden#  '
  local right_ind = '%#TablineHidden#  '
  local ind_width = 3

  -- Calc tabs started from start_idx
  local function get_visible_end(start_idx)
    local w = 0
    if start_idx > 1 then w = w + ind_width end
    local end_idx = start_idx

    for i = start_idx, #tabs do
      local next_w = w + tabs[i].width
      if i > start_idx then next_w = next_w + sep_width end
      if i < #tabs then next_w = next_w + ind_width end

      if next_w > max_width and i > start_idx then
        break
      end

      w = w + tabs[i].width
      if i > start_idx then w = w + sep_width end
      end_idx = i
    end
    return end_idx
  end

  local end_idx = get_visible_end(M.viewport_start)

  -- Push tabs to right if cur tab out of edge
  while current_idx > end_idx do
    M.viewport_start = M.viewport_start + 1
    end_idx = get_visible_end(M.viewport_start)
  end

  -- Render
  local res = ''
  if M.viewport_start > 1 then
    res = res .. left_ind .. sep_str
  end

  for i = M.viewport_start, end_idx do
    res = res .. tabs[i].str
    if i < end_idx then
      res = res .. sep_str
    end
  end

  if end_idx < #tabs then
    res = res .. sep_str .. right_ind
  end

  return res .. '%#TablineFill#'
end

return M
