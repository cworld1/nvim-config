local M = {}

function M.open()
  if vim.fn.executable('yazi') == 0 then
    vim.notify('Yazi is not installed or not in PATH!', vim.log.levels.ERROR)
    return
  end

  local tmpfile = os.tmpname()
  local win = require('snacks').win({
    title = 'Yazi',
    border = 'single',
    backdrop = true,
    minimal = true,
  })

  vim.fn.jobstart(string.format('yazi --chooser-file="%s"', tmpfile), {
    term = true,
    on_exit = function(_, code, _)
      vim.schedule(function()
        win:close()
        if code == 0 then
          local fd = io.open(tmpfile, 'r')
          if fd then
            local is_first = true
            for target_file in fd:lines() do
              if target_file and target_file ~= '' then
                if is_first then
                  vim.cmd.edit(target_file)
                  is_first = false
                else
                  vim.cmd.badd(target_file)
                end
              end
            end
            fd:close()
            os.remove(tmpfile)
          end
        end
      end)
    end
  })

  vim.cmd('startinsert')
end

function M.setup()
  vim.keymap.set('n', '<leader>fy', function() M.open() end, { desc = 'Find via Yazi' })
end

return M
