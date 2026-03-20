-- [Autocmd] Default to treesitter folding
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- Prefer LSP folding if client supports it
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client:supports_method('textDocument/foldingRange') then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
    end
  end,
})

-- [Autocmd] Spelling check for docs
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('TextSpellCheck', { clear = true }),
  pattern = {
    'markdown',
    'text',
    'gitcommit',
    'plaintex',
  },
  callback = function()
    vim.opt_local.spell = true
  end,
})

-- [Autocmd] Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('HighlightOnYank', { clear = true }),
  callback = function() (vim.hl or vim.highlight).on_yank() end,
  desc = 'Highlight yanked text',
})

-- [Autocmd] Change EOL format to unix on save
vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('WriteWithLF', { clear = true }),
  pattern = '*',
  callback = function(args)
    if vim.bo[args.buf].readonly or vim.bo[args.buf].buftype ~= '' or vim.bo[args.buf].binary then return end
    vim.bo[args.buf].fileformat = 'unix'
  end
})

-- [Autocmd] Auto set root
vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('AutoSetRoot', { clear = true }),
  callback = function(args)
    -- Exclude special buffers (terminal, floating windows, etc.)
    if vim.bo[args.buf].buftype ~= '' then return end
    local root = vim.fs.root(args.buf, { '.git', 'Makefile', '.jj' })
    if root then vim.api.nvim_set_current_dir(root) end
  end,
  desc = 'Find root and change current directory',
})
