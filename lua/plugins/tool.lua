local lazy = require('libs.lazy')

-- [Key note] Load on VeryLazy
lazy.load({
  plugin = 'https://github.com/folke/which-key.nvim',
  event = { 'User', pattern = 'VeryLazy' },
  setup = function()
    local whichkey = require('which-key')
    whichkey.add({
      { '<leader>b', group = 'Buffer' },
      { '<leader>c', group = 'Code' },
      { '<leader>f', group = 'Find', icon = '' },
      { '<leader>s', group = 'Search', icon = '󰜎' },
      { '<leader>g', group = 'Git' },
      { '<leader>p', group = 'Panel', icon = '󰏖' },
      { '<leader>u', group = 'UI' },
      { '<leader>q', group = 'Quit' },
    })

    vim.keymap.set('n', '<leader>?',
      function() whichkey.show({ global = false }) end,
      { desc = 'Which-key local keymap' }
    )
  end
})

-- [Diff] Load on open a file
lazy.load({
  plugin = 'https://github.com/nvim-mini/mini.diff',
  event = { 'BufReadPost', 'BufNewFile' },
  setup = function()
    require('mini.diff').setup({
      view = {
        style = 'sign',
        signs = { add = '│', change = '│', delete = '│' },
      },
      mappings = {
        -- Apply hunks inside a visual/operator region
        apply = '<leader>gh',

        -- Reset hunks inside a visual/operator region
        reset = '<leader>gH',

        -- Hunk range textobject to be used inside operator
        -- Works also in Visual mode if mapping differs from apply and reset
        textobject = '<leader>gh',

        -- Go to hunk range in corresponding direction
        goto_first = '[H',
        goto_prev = '[h',
        goto_next = ']h',
        goto_last = ']H',
      },
    })
    vim.keymap.set('n', '<leader>gd', function()
      require('mini.diff').toggle_overlay()
    end, { desc = 'Toggle diff' })
  end
})

-- [Clipboard]
-- vim.pack.add({ "https://github.com/gbprod/yanky.nvim" })
-- -- Custom paste function
-- local function paste_from_unamed()
--   local lines = vim.split(vim.fn.getreg(""), "\n", { plain = true })
--   if #lines == 0 then
--     lines = { "" }
--   end
--   local rtype = vim.fn.getregtype(""):sub(1, 1)
--   return { lines, rtype }
-- end
-- -- Enable new clipboard define
-- vim.g.clipboard = {
--   name = "OSC 52",
--   copy = {
--     ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
--     ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
--   },
--   paste = {
--     ["+"] = paste_from_unamed,
--     ["*"] = paste_from_unamed,
--   },
-- }
-- vim.api.nvim_create_autocmd("TextYankPost", {
--   callback = function()
--     local ev = vim.v.event
--     if ev.operator == "y" and ev.regname == "" then
--       vim.fn.setreg("", ev.regcontents, ev.regtype)
--     end
--   end,
-- })
-- require("yanky").setup({
--   ring = {
--     history_length = 3,
--   },
--   system_clipboard = {
--     sync_with_ring = true,
--   },
-- })
