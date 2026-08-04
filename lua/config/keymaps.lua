local map = vim.keymap.set

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- [Basic]
-- Quit
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit all' })
map('n', '<leader>qr', '<cmd>restart<cr>', { desc = 'Restart' })
-- Save
map('n', '<leader>w', '<cmd>w<cr>', { desc = 'Save file' })
map({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save file' })
map('n', '<leader>wq', '<cmd>wq<cr>', { desc = 'Save and quit' })

-- [View]
map('n', '<leader>us', '<cmd>setlocal spell! spell?<cr>', { desc = 'Toggle spelling' })
map('n', '<leader>uw', '<cmd>setlocal wrap! wrap?<cr>', { desc = 'Toggle wrap' })
map('n', '<leader>ub', '<cmd>lua vim.o.bg = vim.o.bg == "dark" and "light" or "dark"<cr>',
  { desc = 'Toggle background' }
)

-- [Edit]
-- Indent
map('x', '<', '<gv')
map('x', '>', '>gv')
-- Comment
map('n', 'gco', 'o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add comment below' })
map('n', 'gcO', 'O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add comment above' })
-- Move lines
map('n', '<a-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move up' })
map('n', '<a-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move down' })
map('i', '<a-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move up' })
map('i', '<a-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move down' })
map('v', '<a-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv",
  { desc = 'Move up' })
map('v', '<a-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv",
  { desc = 'Move down' })
-- Spelling
map('n', '<leader>cs', 'z=', { desc = 'Spelling suggestions' })

-- [Buffer]
map('n', '<s-h>', '<cmd>bprevious<cr>', { desc = 'Prev buffer' })
map('n', '<s-l>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
-- Moved to Snacks
-- map('n', '<leader>bd', function()
--   local cur = vim.api.nvim_get_current_buf()
--   local alt = vim.fn.bufnr('#')
--   if alt > 0 and vim.api.nvim_buf_is_loaded(alt) then
--     vim.cmd('buffer #')
--   else
--     vim.cmd('bnext')
--   end
--   vim.cmd('bdelete ' .. cur)
-- end, { desc = 'Delete buffer' })
-- map('n', '<leader>bo', function()
--   local current = vim.api.nvim_get_current_buf()
--   for _, buf in ipairs(vim.api.nvim_list_bufs()) do
--     if vim.api.nvim_buf_is_loaded(buf) and buf ~= current then vim.cmd('bdelete ' .. buf) end
--   end
-- end, { desc = 'Delete Other Buffers' })
map('n', '<leader>bn', function()
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
end, { desc = 'New file' })
map('n', '<leader>bn', '<cmd>enew<cr>', { desc = 'New file' }) -- new file
map('n', '<leader>bt', ':set filetype=', { desc = 'Change filetype' })
map('n', '<leader>bp', function()
  local path = vim.fn.expand('%:p:h')
  if path == '' then
    vim.notify('Not a file', vim.log.levels.WARN)
    return
  end
  vim.cmd('silent !open ' .. vim.fn.shellescape(path))
  -- vim.notify(vim.api.nvim_buf_get_name(0), vim.log.levels.INFO)
end, { desc = 'Path of buffer' })


-- [Window]
map('n', '<leader>pd', '<c-w>c', { desc = 'Delete window', remap = true })
-- Split windows
map('n', '<leader>ps', '<c-w>s', { desc = 'Split window below', remap = true })
map('n', '<leader>pv', '<c-w>v', { desc = 'Split window right', remap = true })
-- Move between windows
map('n', '<c-h>', '<c-w>h', { desc = 'Move to left window' })
map('n', '<bs>', '<c-w>h', { desc = 'Move to left window' }) -- Fix <c-h> used as <bs> in some terminal
map('n', '<c-j>', '<c-w>j', { desc = 'Move to below window' })
map('n', '<c-k>', '<c-w>k', { desc = 'Move to above window' })
map('n', '<c-l>', '<c-w>l', { desc = 'Move to right window' })
-- Resize splits
map('n', '<c-left>', function()
  vim.cmd('vertical resize -' .. vim.v.count1)
end, { desc = 'Decrease window width' })
map('n', '<c-down>', function()
  vim.cmd('resize -' .. vim.v.count1)
end, { desc = 'Decrease window height' })
map('n', '<c-up>', function()
  vim.cmd('resize +' .. vim.v.count1)
end, { desc = 'Increase window height' })
map('n', '<c-right>', function()
  vim.cmd('vertical resize +' .. vim.v.count1)
end, { desc = 'Increase window width' })

-- [Functions]
-- Terminal
-- moved to `plugins/snacks`
-- map('n', '<leader>`', '<cmd>vert term<cr>', { desc = 'Open term' })

-- Search
-- Better n/N behavior https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next search result' })
map('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
map('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
map('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev search result' })
map('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })
map('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })
-- Clear search and stop snippet on escape
map({ 'i', 'n', 's' }, '<esc>',
  function()
    vim.cmd('noh')
    return '<esc>'
  end,
  { expr = true, desc = 'Escape and clear hlsearch' }
)

-- Package
map('n', '<leader>pu', function() vim.pack.update() end, { desc = 'Update plugins' })

-- [Others]
-- -- location list
-- map("n", "<leader>xl", function()
--   local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
--   if not success and err then
--     vim.notify(err, vim.log.levels.ERROR)
--   end
-- end, { desc = "Location list" })
-- -- quickfix list
-- map("n", "<leader>xq", function()
--   local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
--   if not success and err then
--     vim.notify(err, vim.log.levels.ERROR)
--   end
-- end, { desc = "Quickfix list" })
