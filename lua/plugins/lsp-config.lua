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
  mason = { 'rumdl', 'prettier', 'mpls' },
  -- lsp = { 'rumdl' },
  conform = {
    -- rumdl will be set automatically with lsp settings
    -- markdown = { 'rumdl' }
    -- markdown = { 'prettier' },
  }
})
vim.filetype.add({ extension = { mdx = 'markdown.mdx' } })
vim.lsp.config('rumdl', {
  cmd = { 'rumdl', 'server', '--verbose' },
  filetypes = { 'markdown' },
  root_markers = { '.git', 'rumdl.toml', '.rumdl.toml', '.config/rumdl.toml', 'pyproject.toml' },
  settings = {
    rumdl = {
      -- MD013 Line length
      -- MD033 Inline HTML
      -- MD034 Bare URL used
      -- MD040 Fenced code blocks should have a language specified
      -- MD041 First line in a file should be a top-level heading
      -- MD045 Images should have alternate text
      disableRules = { 'MD013', 'MD033', 'MD034', 'MD040', 'MD041', 'MD045' },
      settings = {
        -- MD060 Makes significant formatting changes to existing tables
        -- MD084 May trigger false positives in languages that use direction marks
        -- MD088 Whether ASCII or typographic punctuation is correct is a style choice
        -- MD089 CJK spacing
        extendEnable = { 'MD060', 'MD084', 'MD088', 'MD089' },
        exclude = {
          'node_modules',
          'build',
          'dist',
          '*.tmp.md',
        },
        MD032 = { allowLazyContinuation = false },
        MD060 = { enabled = true, style = 'aligned' },
        MD076 = { allowLooseContinuation = true },
        MD088 = { enabled = true, allow = { 'U+201C', 'U+201D', 'U+2018', 'U+2019' } }
      }
    }
  }
})
vim.lsp.enable('rumdl')
Snacks.keymap.set('n', '<localleader>cp', function()
  vim.lsp.start({
    name = 'mpls',
    cmd = {
      'mpls',
      '--theme',
      'dark',
      '--enable-emoji',
      '--enable-footnotes',
    },
    root_dir = vim.fs.root(0, { '.marksman.toml', '.git' })
      or vim.fn.getcwd(),
    filetypes = { 'markdown' },
  })
end, {
  ft = 'markdown',
  desc = '[LSP] Preview file',
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
