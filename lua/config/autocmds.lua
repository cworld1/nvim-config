local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Spelling check for docs
autocmd('FileType', {
  group = augroup('TextSpellCheck', { clear = true }),
  pattern = { 'markdown', 'text', 'gitcommit', 'plaintex', 'typst' },
  callback = function()
    vim.opt_local.wrap = true
    -- vim.opt.spelllang = 'en_us'
    -- vim.opt_local.spelllang = 'en_us'
    vim.opt_local.spell = false
    vim.opt_local.colorcolumn = ''
  end,
})

-- No commenting on next line when o or O in normal mode
autocmd('FileType', {
  group = augroup('DisableAutoComment', { clear = true }),
  pattern = '*',
  callback = function(event)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(event.buf) then
        vim.bo[event.buf].formatoptions = vim.bo[event.buf].formatoptions:gsub('[cro]', '')
      end
    end)
  end,
})

-- Highlight on yank and paste
vim.api.nvim_create_autocmd({ 'TextYankPost', 'TextPutPost' }, {
  group = vim.api.nvim_create_augroup('HighlightOnYankAndPaste', {
    clear = true,
  }),
  callback = function()
    vim.hl.hl_op()
  end,
  desc = 'Highlight text when yank and paste',
})

-- Change EOL format to unix on save
autocmd('BufWritePre', {
  callback = function(args)
    local buf = args.buf
    local get_opt = vim.api.nvim_get_option_value
    if get_opt('readonly', { buf = buf })
      or get_opt('buftype', { buf = buf }) ~= ''
      or get_opt('binary', { buf = buf }) then
      return
    end
    vim.api.nvim_set_option_value('fileformat', 'unix', { buf = buf })
  end
})

-- Auto set root
autocmd('BufEnter', {
  group = augroup('AutoSetRoot', { clear = true }),
  callback = function(args)
    -- Exclude special buffers (terminal, floating windows, etc.)
    if vim.bo[args.buf].buftype ~= '' then return end
    local root = vim.fs.root(args.buf, { '.git', 'Makefile', '.jj' })
    if root then vim.api.nvim_set_current_dir(root) end
  end,
  desc = 'Find root and change current directory',
})
