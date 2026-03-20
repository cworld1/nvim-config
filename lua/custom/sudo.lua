local utils = require('libs.utils')
local M = {}

local aug = vim.api.nvim_create_augroup('sudo_save', { clear = true })

-- Check file or path writable
M.is_writable = function(path)
  if path == '' then return true end
  -- Check file permission
  if vim.fn.filereadable(path) == 1 then
    return vim.fn.filewritable(path) == 1
  else
    -- Check path writable
    local dir = vim.fn.fnamemodify(path, ':h')
    return vim.fn.filewritable(dir) == 2
  end
end

-- Sudo save
M.do_sudo_save = function(buf, path)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local data = table.concat(lines, '\n') .. '\n'

  -- Check if password needed
  local check = vim.system({ 'sudo', '-n', 'true' }):wait()
  local stdin_data = data

  if check.code ~= 0 then
    local pwd = vim.fn.inputsecret('Sudo Password for ' .. vim.fn.fnamemodify(path, ':t') .. ': ')

    -- Cancel
    if not pwd or pwd == '' then
      vim.notify('\n[Sudo] Canceled.', vim.log.levels.WARN)
      return
    end
    stdin_data = pwd .. '\n' .. data
  end

  -- Save with sudo tee
  local obj = vim.system({ 'sudo', '-S', 'tee', path }, { stdin = stdin_data }):wait()

  if obj.code == 0 then
    vim.bo[buf].modified = false
    vim.cmd('checktime ' .. buf)
    vim.notify('\n[Sudo] Successfully saved: ' .. path, vim.log.levels.INFO)
  else
    vim.notify('\n[Sudo] Failed to save: ' .. (obj.stderr or ''), vim.log.levels.ERROR)
  end
end

M.setup = function()
  -- Do not load on Windows
  if utils.is_windows() then return end

  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    group = aug,
    callback = function(args)
      local buf = args.buf
      local path = vim.api.nvim_buf_get_name(buf)

      -- Filter not float window, terminal or untitled buffer
      if vim.bo[buf].buftype ~= '' and vim.bo[buf].buftype ~= 'acwrite' then return end
      if path == '' or path:match('^[%w%+%.%-]+://') then return end

      -- Not writable; need sudo save instead
      if not M.is_writable(path) then
        vim.bo[buf].buftype = 'acwrite'
        vim.api.nvim_create_autocmd('BufWriteCmd', {
          group = aug,
          buffer = buf,
          callback = function() M.do_sudo_save(buf, path) end
        })
      end
    end
  })
end

return M
