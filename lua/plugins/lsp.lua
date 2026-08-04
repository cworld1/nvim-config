local lazy = require('libs.lazy')
local utils = require('libs.utils')
local config = require('plugins.lsp-config')

-- [Dependencies] Load on run `Mason` command, key, and event
lazy.load({
  plugin = 'https://github.com/mason-org/mason.nvim',
  cmd = { 'Mason', 'MasonInstall', 'MasonUninstall', 'MasonLog', 'MasonUpdate' },
  keys = {
    { 'n', '<leader>pm', function() vim.cmd('Mason') end, { desc = '[Panel] Mason' } },
    { 'n', '<leader>pM', function()
      vim.cmd('Mason')
      -- Install in background
      local registry = require('mason-registry')
      registry.refresh(function()
        for _, pkg_name in ipairs(config.mason) do
          local ok, pkg = pcall(registry.get_package, pkg_name)
          if ok and not pkg:is_installed() then
            vim.schedule(function()
              pkg:install()
              vim.notify('[Mason] Auto installing ' .. pkg_name, vim.log.levels.INFO)
            end)
          end
        end
      end)
    end, { desc = '[Panel] Mason with install' } }
  },
  setup = function()
    require('mason').setup({
      ui = {
        icons = {
          package_installed = '✓',
          package_pending = '➜',
          package_uninstalled = '✗',
        },
      },
    })
  end
})
-- Path injection
-- lspconfig can activate lsp without mason loaded
-- can save up ~200 ms when open a file via nvim directly from terminal prompt
local env = vim.env
local mason_bin = vim.fs.joinpath(vim.fn.stdpath('data'), 'mason', 'bin')
local is_windows = require('libs.utils').is_windows()
if is_windows then mason_bin = mason_bin:gsub('/', '\\') end
if not env.PATH:find(mason_bin, 1, true) then
  local sep = is_windows and ';' or ':'
  env.PATH = mason_bin .. sep .. env.PATH
end

-- [LSP] Load when opening files or delay
lazy.load({
  plugin = 'https://github.com/neovim/nvim-lspconfig',
  event = { 'User', pattern = 'VeryLazy' },
  setup = function()
    vim.lsp.enable(config.lsp)
  end
})
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable inline hint
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(
        not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
        { bufnr = ev.buf }
      )
    end
    -- Enable fold tag
    -- Prefer LSP folding if client supports it
    if client and client:supports_method('textDocument/foldingRange') then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
    else
      vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end

    -- LSP keymaps
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = ev.buf, desc = 'LSP hover' })
    vim.keymap.set('n', '<leader>ch', vim.lsp.buf.hover, { buffer = ev.buf, desc = 'LSP hover' })
    -- Moved to Snacks
    -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc='Goto definition'})
    -- vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = ev.buf, desc='Goto declaration'})
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, {
      buffer = ev.buf,
      desc =
      'List references'
    })
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation,
      { buffer = ev.buf, desc = 'Goto implementation' })
    vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition,
      { buffer = ev.buf, desc = 'Type definition' })
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename,
      { buffer = ev.buf, desc = 'Rename symbol' })
    vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action,
      { buffer = ev.buf, desc = 'Code action' })
    vim.keymap.set('i', '<c-k>', vim.lsp.buf.signature_help,
      { buffer = ev.buf, desc = 'Signature help' })
    vim.keymap.set('n', '<leader>pl', '<cmd>checkhealth vim.lsp<cr>', { desc = '[Panel] Lsp info' })
    -- vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format,
    --   { buffer = ev.buf, desc = 'Format code' })
  end,
})

-- [Formatter] Multi-trigger: load on save or keymap
vim.pack.add({ 'https://github.com/stevearc/conform.nvim' })
lazy.load({
  plugin = 'https://github.com/stevearc/conform.nvim',
  event = 'BufWritePre',
  cmd = { 'ConformInfo' },
  keys = {
    { 'n', '<leader>cf', function()
      require('conform').format({ async = true, lsp_format = 'fallback' })
    end, { desc = 'Format file' } },
    { 'n', '<leader>pc', function() vim.cmd('ConformInfo') end, { desc = '[Panel] Conform' } }
  },
  setup = function()
    require('conform').setup({
      formatters_by_ft = config.conform,
      format_after_save = {
        async = true,
        lsp_format = 'fallback',
      },
    })
  end
})

-- [Diagnostic] Load after LSP attaches
-- https://github.com/rachartier/tiny-inline-diagnostic.nvim/issues/112#issuecomment-2784644922
lazy.load({
  plugin = 'https://github.com/rachartier/tiny-inline-diagnostic.nvim',
  event = { 'User', pattern = 'VeryLazy' },
  setup = function()
    require('tiny-inline-diagnostic').setup({
      preset = 'modern',
      signs = { diag = '-' },
      transparent_cursorline = true,
      options = {
        virt_texts = { priority = 2048 },
        show_source = { enabled = true },
      },
    })
    vim.diagnostic.config({ virtual_text = false })

    -- Keymap
    local diagnostic_goto = function(next, severity)
      return function()
        vim.diagnostic.jump({
          count = (next and 1 or -1) * vim.v.count1,
          severity = severity and vim.diagnostic.severity[severity] or nil,
          float = true,
        })
      end
    end
    vim.keymap.set('n', '<leader>cl', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
    vim.keymap.set('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic' })
    vim.keymap.set('n', '[d', diagnostic_goto(false), { desc = 'Prev Diagnostic' })
    vim.keymap.set('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
    vim.keymap.set('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Prev Error' })
    vim.keymap.set('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
    vim.keymap.set('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Prev Warning' })
  end
})

-- [Completion] Load on InsertEnter and CmdlineEnter
lazy.load({
  plugin = { { src = 'https://github.com/Saghen/blink.cmp', version = vim.version.range('1') } },
  event = { 'InsertEnter', 'CmdlineEnter' },
  setup = function()
    require('blink.cmp').setup({
      -- https://cmp.saghen.dev/configuration/keymap.html#presets
      keymap = { preset = 'super-tab' },
      appearance = { nerd_font_variant = 'mono' },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      fuzzy = { implementation = 'prefer_rust_with_warning' },
      signature = { enabled = true },
      completion = {
        documentation = {
          auto_show = true,
          window = { max_width = 65, }
        },
        ghost_text = { enabled = true },
        menu = {
          scrollbar = true,
          auto_show_delay_ms = 200,
          draw = {
            columns = {
              { 'kind_icon', 'label', gap = 1 },
              { 'menu' }
            },
            components = {
              -- https://cmp.saghen.dev/recipes.html#mini-icons
              kind_icon = {
                text = function(ctx)
                  local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
                  return kind_icon
                end,
                -- (optional) use highlights from mini.icons
                highlight = function(ctx)
                  local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                  return hl
                end,
              },
              -- kind = {
              --   -- (optional) use highlights from mini.icons
              --   highlight = function(ctx)
              --     local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
              --     return hl
              --   end,
              -- },
              label = {
                width = { fill = true, max = 30 },
                text = function(ctx) return ctx.label .. ctx.label_detail end,
              },
              menu = {
                text = function(ctx)
                  local menu_labels = {
                    lsp = '[LSP]',
                    buffer = '[Buffer]',
                    snippets = '[Snippet]',
                    path = '[Path]',
                    Cmdline = '' -- no need to show text
                  }
                  return menu_labels[ctx.source_name] or ('[' .. ctx.source_name .. ']')
                end,
              },
            },
          },
        }
      },
      cmdline = {
        -- completion = {
        --   menu = {
        --     auto_show = true,
        --   }
        -- },
      },
    })
  end
})
