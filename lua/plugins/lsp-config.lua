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

-- Basic
extend({
  mason = { 'prettier' },
  conform = {
    graphql = { 'prettier' },
    handlebars = { 'prettier' },
    json = { 'prettier' },
    jsonc = { 'prettier' },
    yaml = { 'prettier' },
  },
})


-- Lua
extend({
  mason = { 'lua-language-server' },
  lsp = { 'lua_ls' },
})

-- Markdown
extend({
  mason = { 'rumdl', 'prettier' },
  lsp = { 'rumdl' },
  conform = {
    -- rumdl will be set automatically with lsp settings
    -- markdown = { 'rumdl' }
    -- markdown = { 'prettier' },
  }
})
vim.filetype.add({ extension = { mdx = 'markdown.mdx' } })
vim.lsp.config('rumdl', {
  root_markers = { '.git', 'rumdl.toml', '.rumdl.toml', 'pyproject.toml' },
  settings = {
    rumdl = {
      extendEnable = { 'MD060' },
      -- MD013 Line length
      -- MD033 Inline HTML
      -- MD034 Bare URL used
      -- MD045 Images should have alternate text
      disable = { 'MD013', 'MD033', 'MD034', 'MD045' },
      exclude = {
        'node_modules',
        'build',
        'dist',
        '*.tmp.md',
      },
      MD060 = { style = 'aligned' },
      MD076 = { allowLooseContinuation = true }
    }
  }
})

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
  mason = { 'tsc', 'css-lsp', 'prettier' },
  lsp = { 'tsc', 'cssls' },
  conform = {
    css = { 'prettier' },
    html = { 'prettier' },
    javascript = { 'prettier' },
    javascriptreact = { 'prettier' },
    less = { 'prettier' },
    scss = { 'prettier' },
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
    vue = { 'prettier' },
  }
})

-- Astro
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#astro
extend({
  mason = { 'astro-language-server' },
  lsp = { 'astro' },
  conform = { astro = { 'prettier' } }
})
-- ts 6 is needed as they contain libs
vim.lsp.config('astro', {
  init_options = {
    typescript = {
      tsdk = vim.fn.stdpath('data') .. '/typescript-v6-compatible/node_modules/typescript/lib',
    },
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
-- extend({
--   mason = { 'shfmt', 'bash-language-server' },
--   lsp = { 'bashls' },
-- })

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
