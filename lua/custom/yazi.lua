local M = {}

local function open_selected_files(tmpfile)
  local file = io.open(tmpfile, 'r')
  if not file then
    return
  end
  local first = true
  for path in file:lines() do
    if path ~= '' then
      vim.cmd({
        cmd = first and 'edit' or 'badd',
        args = { path },
      })

      first = false
    end
  end
  file:close()
end

function M.open()
  if vim.fn.executable('yazi') == 0 then
    vim.notify('Yazi is not installed or not in PATH!', vim.log.levels.ERROR)
    return
  end

  local tmpfile = vim.fn.tempname()
  local win = require('snacks').win({
    title = ' Yazi ',
    border = 'single',
    backdrop = true,
    minimal = true,
  })
  vim.fn.jobstart({ 'yazi', '--chooser-file', tmpfile }, {
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        win:close()
        if code == 0 then
          open_selected_files(tmpfile)
        end
        os.remove(tmpfile)
      end)
    end,
  })
  vim.cmd('startinsert')
end

function M.setup()
  vim.keymap.set('n', '<leader>fy', M.open, { desc = 'Find via Yazi', })
end

return M
