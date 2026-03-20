local M = {}
M.config = {
  filename_width = nil,
  icons = { branch = '' },
  hide_filename_by_ft = {},
}

-- [Filetype]
local function filetype()
  return vim.bo.filetype ~= '' and vim.bo.filetype or 'plaintext'
end

-- [Filename]
local function filename(max_w)
  if M.config.hide_filename_by_ft[filetype()] then return '' end
  local name = vim.fn.expand('%')
  if name == '' then return '[No Name]' end
  name = name:gsub('\\', '/')
  if max_w and #name > max_w then
    return name:sub(1, max_w - 1) .. '...'
  end
  return name
end

-- [Git]
-- Await sync to get Git branch/worktree
local function update_git_branch(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  -- Not handle float & terminal window
  if vim.bo[bufnr].buftype ~= ''
    or vim.b[bufnr].git_fetching
    or vim.b[bufnr].git_not_repo then
    return
  end

  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == '' then return end
  -- Block network/virtual paths (e.g. ssh://, oil://) to prevent reporting errors
  if filepath == '' or filepath:match('^[%w%+%.%-]+://') then return end

  local dir = vim.fn.fnamemodify(filepath, ':h')
  vim.b[bufnr].git_fetching = true

  -- vim.system to start async request
  vim.system({ 'git', '-C', dir, 'rev-parse', '--abbrev-ref', 'HEAD' },
    { text = true, timeout = 1000 },
    function(obj)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.b[bufnr].git_fetching = false

          if obj.code == 0 and obj.stdout and obj.stdout ~= '' then
            vim.b[bufnr].git_branch = vim.trim(obj.stdout)
          else
            -- Once can't find a branch will add a not repo tag
            vim.b[bufnr].git_branch = ''
            vim.b[bufnr].git_not_repo = true
          end
          vim.cmd('redrawstatus')
        end
      end)
    end)
end

-- Only fetch branches when switching buffers, saving files, or window focus
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'FocusGained' }, {
  group = vim.api.nvim_create_augroup('MyStatuslineGit', { clear = true }),
  callback = function(args)
    update_git_branch(args.buf)
  end,
})

-- [Status]
-- Public API used by statusline expansion
_G.statusline = _G.statusline or {}

_G.statusline.gitbranch = function()
  local branch = vim.b.git_branch
  if not branch or branch == '' then return '' end

  local icon = (M.config.icons and M.config.icons.branch) or ''
  return icon .. ' ' .. branch .. ' | '
end

_G.statusline.filename = function()
  local fn = filename(M.config.filename_width)
  if fn and fn ~= '' then return fn .. ' ' end
  return ''
end

_G.statusline.filetype = filetype

local function apply()
  local left = ' %{v:lua.statusline.gitbranch()}%{v:lua.statusline.filename()}%m'
  local right = ' %=%{v:lua.statusline.filetype()} | %2p%% | %l:%c '
  vim.o.statusline = left .. right
end

M.setup = function(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  apply()
end

return M
