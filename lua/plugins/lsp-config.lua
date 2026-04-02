local M = {}

-- [Env] mason
-- `:Mason` to see the list
-- https://mason-registry.dev/registry/list
M.mason = {
  -- LSP
  'lua-language-server', -- lua
  'vtsls', -- typescript
  'css-lsp', -- css
  'marksman', -- markdown
  'ty', -- python
  -- Formatter
  'prettier', -- front-end
  'shfmt', -- shell
  'ruff' -- python
}

-- [Lsp] lspconfig
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
M.lsp = { 'lua_ls', 'vtsls', 'cssls', 'vue_ls', 'marksman', 'ty', 'ruff' }

-- [Formatter] conform
-- https://github.com/stevearc/conform.nvim#formatters
-- Or use `:help conform-formatters`
M.conform = {
  markdown = { 'prettier' },
  vue = { 'prettier' },
  python = function(bufnr)
    if require('conform').get_formatter_info('ruff_format', bufnr).available then
      return { 'ruff_format' }
    else
      return { 'isort', 'black' }
    end
  end,
  css = { 'prettier' },
}

-- [Specific]
local vue_language_server_path = vim.fn.stdpath('data') ..
  '/mason/packages/vue-language-server/node_modules/@vue/language-server'
local vue_plugin = {
  name = '@vue/typescript-plugin',
  location = vue_language_server_path,
  languages = { 'vue' },
  configNamespace = 'typescript',
}
vim.lsp.config('vtsls', {
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          vue_plugin,
        },
      },
    },
  },
  filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
})

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
