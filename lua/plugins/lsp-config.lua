local M = {}

-- [Dependency] mason
-- - `:Mason`
-- - https://mason-registry.dev/registry/list
-- [Lsp] lspconfig
-- - https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
-- [Formatter] conform
-- - https://github.com/stevearc/conform.nvim#formatters
-- - `:help conform-formatters`

-- Lua
M = vim.tbl_deep_extend('force', M, {
  mason = { 'lua-language-server' },
  lsp = { 'lua_ls' },
})

-- Markdown
M = vim.tbl_deep_extend('force', M, {
  mason = { 'marksman' },
  lsp = { 'marksman' },
})
vim.filetype.add({ extension = { mdx = 'markdown.mdx', } })

-- Python
M = vim.tbl_deep_extend('force', M, {
  mason = { 'ty', 'ruff' }, -- `ty` for lsp, `ruff` for formatter
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
M = vim.tbl_deep_extend('force', M, {
  mason = { 'vtsls', 'css-lsp', 'prettier' },
  lsp = { 'vtsls', 'cssls' },
  conform = {
    css = { 'prettier' },
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    vue = { 'prettier' },
  },
})

-- Vue
M = vim.tbl_deep_extend('force', M, {
  mason = { 'vue-language-server' },
  lsp = { 'vue_ls' },
})
local function get_vue_plugin()
  local vue_language_server_path = vim.fn.stdpath('data') ..
    '/mason/packages/vue-language-server/node_modules/@vue/language-server'
  return {
    name = '@vue/typescript-plugin',
    location = vue_language_server_path,
    languages = { 'vue' },
    configNamespace = 'typescript',
  }
end
vim.lsp.config('vtsls', {
  settings = {
    vtsls = {
      tsserver = { globalPlugins = { get_vue_plugin() } },
    },
  },
  filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
})

-- Shell
M = vim.tbl_deep_extend('force', M, {
  mason = { 'shfmt' },
  lsp = { 'bashls' },
})

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
