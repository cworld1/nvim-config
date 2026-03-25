local utils = require('libs.utils')

local M = {}
M.config = {
  get_git_root = function(filepath)
    return vim.fs.root(filepath, '.git')
  end,
  stage = {
    -- action = require('snacks.picker').actions.git_stage,
    action = nil,
  },
  blame = {
    enabled = true,
    msg_template = '  <author> • <date> • <summary> • <sha>',
    msg_not_committed = '  Not Committed Yet',
    highlight_group = 'Comment',
    delay = 250,
    ignored_ft = {}, -- Ignored filetypes
    max_summary_length = 50,
  }
}

-- [Stage] current file
-- Returns a two‑character string such as " M", "M ", "??", etc.
local function get_file_status(git_root, rel_path)
  local out = vim.fn.systemlist({
    'git',
    '-C',
    git_root,
    'status',
    '--porcelain=v1',
    '--',
    rel_path,
  })
  if #out == 0 then return nil end
  return out[1]:sub(1, 2)
end

--- Toggle the stage/unstage state of the file in the current buffer.
function M.toggle_stage()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == '' then
    vim.notify('No associated file found', vim.log.levels.ERROR)
    return
  end
  local git_root = M.config.get_git_root(bufname)
  if not git_root then
    vim.notify('Git repo not found', vim.log.levels.ERROR)
    return
  end
  local rel_path = vim.fn.fnamemodify(bufname, ':.') -- path relative to repo root
  local status = get_file_status(git_root, rel_path)
  if not status then
    vim.notify('File is not tracked by Git', vim.log.levels.ERROR)
    return
  end

  -- Picker object interface `Snacks.picker.git_stage`
  M.config.stage.action({
    selected = { cwd = git_root, status = status, file = rel_path, },
    refresh = function()
      local action = status:sub(2, 2) == ' ' and 'unstaged' or 'staged'
      vim.notify(
        string.format('File %s %s', rel_path, action),
        vim.log.levels.INFO
      )
    end,
  })
end

-- [Blame] current line
local NS = vim.api.nvim_create_namespace('GitBlame')
-- Cache pool
local b_state = {}
local fetch_timers = {}
local current_author = nil

local function escape_gsub(s) return (s:gsub('%%', '%%%%')) end

local function truncate(str, max)
  return (max and max > 0 and #str > max) and (str:sub(1, max) .. '...') or str
end

-- Parse blame cmd info
local function parse_porcelain(stdout)
  local blames, commit_cache = {}, {}
  local c_sha, c_final, c_size = nil, nil, nil

  for line in stdout:gmatch('([^\n]+)') do
    local sha, _, final_line, group_size = line:match('^([0-9a-fA-F]+)%s+(%d+)%s+(%d+)%s+(%d+)')
    if sha then
      c_sha, c_final, c_size = sha, tonumber(final_line), tonumber(group_size)
      if not commit_cache[sha] then commit_cache[sha] = { sha = sha } end
      local commit = commit_cache[sha]
      for i = 0, c_size - 1 do blames[c_final + i] = commit end
    elseif c_sha and line:sub(1, 1) ~= '\t' then
      local key, val = line:match('^(%S+)%s+(.*)')
      if key and val then
        local commit = commit_cache[c_sha]
        if key == 'author' then
          commit.author = val
        elseif key == 'author-time' then
          commit.date = tonumber(val)
        elseif key == 'committer' then
          commit.committer = val
        elseif key == 'committer-time' then
          commit.committer_date = tonumber(val)
        elseif key == 'summary' then
          commit.summary = val
        end
      end
    end
  end
  return blames
end

local function format_blame(commit)
  if not commit then return nil end
  if commit.sha and commit.sha:match('^0+$') then return M.config.blame.msg_not_committed end

  local author = commit.author or 'Unknown'
  if current_author and author == current_author then author = 'You' end

  local date_str = commit.date and utils.time_ago(commit.date) or ''

  local summary = truncate(commit.summary or '', M.config.blame.max_summary_length)
  local sha = commit.sha and commit.sha:sub(1, 7) or ''

  local text = M.config.blame.msg_template
  text = text:gsub('<author>', escape_gsub(author))
  text = text:gsub('<date>', escape_gsub(date_str))
  text = text:gsub('<summary>', escape_gsub(summary))
  text = text:gsub('<sha>', escape_gsub(sha))
  return text
end

local function clear_blame(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_del_extmark, buf, NS, 1)
  end
end

local function show_blame(buf)
  if not M.config.blame.enabled or vim.api.nvim_get_current_buf() ~= buf or vim.fn.mode() == 'i' then return end
  local st = b_state[buf]
  if not st or not st.blames or st.tick ~= vim.api.nvim_buf_get_changedtick(buf) then
    clear_blame(buf)
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local text = format_blame(st.blames[line])
  if not text then return clear_blame(buf) end

  pcall(vim.api.nvim_buf_set_extmark, buf, NS, line - 1, 0, {
    id = 10,
    virt_text = { { text, M.config.blame.highlight_group } },
    virt_text_pos = 'eol',
    hl_mode = 'combine',
  })
end

local function fetch_blame(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end

  local filepath = vim.api.nvim_buf_get_name(buf)
  if filepath == '' or filepath:match('^[%w%+%.%-]+://') then return end
  if vim.tbl_contains(M.config.blame.ignored_ft, vim.bo[buf].filetype) then return end

  local root = M.config.get_git_root(filepath)
  if not root then return end

  local stats = vim.uv.fs_stat(filepath)
  if stats and stats.size > 1.5 * 1024 * 1024 then return end

  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines == 0 then return end

  local stdin = table.concat(lines, '\n') .. '\n'
  local cmd = { 'git', '--no-pager', '-C', root, 'blame', '-b', '-p', '-w', '--date', 'unix',
    '--contents', '-', filepath }

  local st = b_state[buf] or {}
  b_state[buf] = st
  if st.job then st.job:kill('sigterm') end

  st.job = vim.system(cmd, { stdin = stdin, text = true }, function(obj)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then return end
      st.job = nil
      if obj.code == 0 and obj.stdout then
        st.blames = parse_porcelain(obj.stdout)
        st.tick = tick
        if vim.api.nvim_get_current_buf() == buf and vim.fn.mode() ~= 'i' then show_blame(buf) end
      end
    end)
  end)
end

local function queue_fetch(bufnr)
  if not M.config.blame.enabled or not vim.api.nvim_buf_is_valid(bufnr) then return end
  if fetch_timers[bufnr] then fetch_timers[bufnr]:stop() else fetch_timers[bufnr] = vim.uv.new_timer() end
  fetch_timers[bufnr]:start(M.config.blame.delay, 0,
    vim.schedule_wrap(function() fetch_blame(bufnr) end))
end

function M.toggle_blame()
  M.config.blame.enabled = not M.config.blame.enabled
  if M.config.blame.enabled then
    for _, win in ipairs(vim.api.nvim_list_wins()) do queue_fetch(vim.api.nvim_win_get_buf(win)) end
  else
    for buf, _ in pairs(b_state) do clear_blame(buf) end
  end
end

-- [Setup]
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  -- Stage
  vim.keymap.set('n', '<leader>ga', M.toggle_stage, { desc = 'Toggle git stage' })

  -- Blame
  if M.config.blame.enabled then
    local aug = vim.api.nvim_create_augroup('MyGit', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'BufWritePost', 'InsertLeave' }, {
      group = aug, callback = function(args) if vim.fn.mode() ~= 'i' then queue_fetch(args.buf) end end
    })
    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
      group = aug,
      callback = function(args)
        clear_blame(args.buf)
        if vim.fn.mode() ~= 'i' then queue_fetch(args.buf) end
      end
    })
    vim.api.nvim_create_autocmd('CursorMoved', {
      group = aug, callback = function(args) show_blame(args.buf) end
    })
    vim.api.nvim_create_autocmd('InsertEnter', {
      group = aug, callback = function(args) clear_blame(args.buf) end
    })
    vim.api.nvim_create_autocmd('BufWipeout', {
      group = aug,
      callback = function(args)
        local b = args.buf
        if fetch_timers[b] then
          if not fetch_timers[b]:is_closing() then fetch_timers[b]:close() end
          fetch_timers[b] = nil
        end
        if b_state[b] then
          if b_state[b].job then b_state[b].job:kill('sigterm') end
          b_state[b] = nil
        end
      end
    })
    vim.system({ 'git', 'config', 'user.name' }, { text = true }, function(obj)
      if obj.code == 0 and obj.stdout then current_author = vim.trim(obj.stdout) end
    end)
    for _, win in ipairs(vim.api.nvim_list_wins()) do queue_fetch(vim.api.nvim_win_get_buf(win)) end
  end
  vim.keymap.set('n', '<leader>ub', function() M.toggle_blame() end, { desc = 'Toggle Git Blame' })
end

return M
