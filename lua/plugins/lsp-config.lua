local M = {
  mason = {},
  lsp = {},
  conform = {},
}

local function extend(opts)
  if opts.mason then vim.list_extend(M.mason, opts.mason) end
  if opts.lsp then vim.list_extend(M.lsp, opts.lsp) end
  if opts.conform then M.conform = vim.tbl_deep_extend('force', M.conform, opts.conform) end
end

-- [Dependency] mason
-- - `:Mason`
-- - https://mason-registry.dev/registry/list
-- [Lsp] lspconfig
-- - https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
-- [Formatter] conform
-- - https://github.com/stevearc/conform.nvim#formatters
-- - `:help conform-formatters`

-- Lua
extend({
  mason = { 'lua-language-server' },
  lsp = { 'lua_ls' },
})

-- Markdown
extend({
  mason = { 'marksman' },
  lsp = { 'marksman' },
})
vim.filetype.add({ extension = { mdx = 'markdown.mdx', } })

-- Python
extend({
  mason = { 'ty', 'ruff' },
  lsp = { 'ty', 'ruff' },
  conform = {
    python = function(bufnr)
      if require('conform').get_formatter_info('ruff_format', bufnr).available then
        return { 'ruff_format' }
      else
        return { 'isort', 'black' }
      end
    end,
  },
})

-- Front-end
extend({
  mason = { 'vtsls', 'css-lsp', 'prettier' },
  lsp = { 'vtsls', 'cssls' },
  conform = {
    html = { 'prettier' },
    css = { 'prettier' },
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    vue = { 'prettier' },
    yaml = { 'prettier' },
  },
})

-- Vue
-- extend({
--   mason = { 'vue-language-server' },
--   lsp = { 'vue_ls' },
-- })
-- local function get_vue_plugin()
--   local vue_language_server_path = vim.fn.stdpath('data') ..
--     '/mason/packages/vue-language-server/node_modules/@vue/language-server'
--   return {
--     name = '@vue/typescript-plugin',
--     location = vue_language_server_path,
--     languages = { 'vue' },
--     configNamespace = 'typescript',
--   }
-- end
-- vim.lsp.config('vtsls', {
--   settings = {
--     vtsls = {
--       tsserver = { globalPlugins = { get_vue_plugin() } },
--     },
--   },
--   filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
-- })

-- C/C++
extend({
  -- mason = { 'clangd' },
  lsp = { 'clangd' }
})

-- Shell
extend({
  mason = { 'shfmt', 'bash-language-server' },
  lsp = { 'bashls' },
})

-- Copilot
-- extend({
--   mason = { 'copilot-language-server' },
--   lsp = { 'copilot' },
-- })

-- Others
vim.g.markdown_fenced_languages = {
  'sh', 'bash=sh',
  'python', 'py=python',
  'javascript', 'js=javascript',
  'typescript', 'ts=typescript',
  'html',
  'css',
  'json',
  'lua',
  'vim',
}

return M
