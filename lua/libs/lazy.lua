-- Lightweight lazy loading implementation
local M = {}
local stats = { start = nil, cached_rtps = nil, loaded = 0 }

M.config = {
  statistic = false,
  trigger_verylazy = false
}

local function once_autocmd(event, pattern, fn)
  vim.api.nvim_create_autocmd(event, {
    pattern = pattern,
    once = true,
    callback = fn,
  })
end

--- Create an autocmd that fires once and calls `loader`
local function add_event_autocmd(events, fn)
  local event_name = events[1]
  local pattern = events[2] or events.pattern

  -- Add pattern for User events
  if event_name == 'User' and pattern then
    once_autocmd(event_name, pattern, fn)
  else
    once_autocmd(events, nil, fn)
  end
end

--- Autocmd for filetype triggers
local function add_ft_autocmd(fts, fn)
  once_autocmd('FileType', fts, fn)
end

--- Register a user command that loads the plugin on first use
local function add_cmd_triggers(cmds, fn)
  for _, cmd in ipairs(cmds) do
    vim.api.nvim_create_user_command(
      cmd,
      function(args)
        vim.api.nvim_del_user_command(cmd)
        fn()
        -- Re-execute the original command with its arguments
        local cmd_string = cmd
        if args.range > 0 then
          cmd_string = args.line1 .. ',' .. args.line2 .. cmd_string
        end
        if args.args and args.args ~= '' then
          cmd_string = cmd_string .. ' ' .. args.args
        end
        if args.bang then cmd_string = cmd_string .. '!' end
        vim.cmd(cmd_string)
      end,
      { nargs = '*', bang = true, range = true, complete = 'file' }
    )
  end
end

--- Register a key‑map that loads the plugin on first press
local function add_key_triggers(keys, fn, restore)
  for _, key_cfg in ipairs(keys) do
    local mode = key_cfg[1] or key_cfg.mode or 'n'
    local lhs = key_cfg[2] or key_cfg.lhs
    local rhs = key_cfg[3] or key_cfg.rhs
    local opts = key_cfg[4] or key_cfg.opts or {}

    if lhs then
      vim.keymap.set(mode, lhs, function()
        if restore then vim.keymap.set(mode, lhs, rhs, opts) end
        fn()
        if type(rhs) == 'function' then
          rhs()
        elseif type(rhs) == 'string' then
          local new_keys = vim.api.nvim_replace_termcodes(rhs, true, false, true)
          vim.api.nvim_feedkeys(new_keys, 'm', false)
        else
          local new_keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
          vim.api.nvim_feedkeys(new_keys, 'i', false)
        end
      end, opts)
    end
  end
end

local function make_loader(plugins, setup)
  local loaded = false -- use per‑call local_variable
  return function()
    if loaded then return end
    loaded = true

    if M.config.statistic then
      stats.loaded = stats.loaded + #plugins
    end

    if #plugins > 0 then
      -- Batch loading & catching errors with pcall
      local ok, err = pcall(vim.pack.add, plugins)
      if not ok then vim.notify('Plugin load error: ' .. err, vim.log.levels.WARN) end
    end

    if setup then setup() end
  end
end

--- Public API
--- Multi‑trigger loader: supports multiple loading conditions
--- @param cfg table Configuration with triggers and setup
---   config.plugin        string|table – Plugin URL(s)
---   config.event         string|table|nil – Event trigger(s)
---   config.cmd           string|table|nil – Command trigger(s)
---   config.keys          table|nil – Key trigger(s) { { mode, lhs, rhs, opts } }
---   config.ft            string|table|nil – Filetype trigger(s)
---   config.setup         function|nil – Setup function after loading
---   config.restore_keys  boolean|nil – Restore keymaps after load (default true)
function M.load(cfg)
  -- Plugins
  local plugins = type(cfg.plugin) == 'string'
    and { cfg.plugin } or cfg.plugin or {}
  -- Load the plugin(s) and run optional setup
  local loader = make_loader(plugins, cfg.setup)

  -- Triggers
  if cfg.event then
    local ev = type(cfg.event) == 'string' and { cfg.event } or cfg.event
    add_event_autocmd(ev, loader)
  end
  if cfg.cmd then
    local cmds = type(cfg.cmd) == 'string' and { cfg.cmd } or cfg.cmd
    add_cmd_triggers(cmds, loader)
  end
  if cfg.keys then
    add_key_triggers(cfg.keys, loader, cfg.restore_keys ~= false)
  end
  if cfg.ft then
    local fts = type(cfg.ft) == 'string' and { cfg.ft } or cfg.ft
    add_ft_autocmd(fts, loader)
  end
end

-- Trigger VeryLazy event after UI is ready
function M.trigger_verylazy()
  once_autocmd('UIEnter', nil, function()
    vim.schedule(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy' })
    end)
  end)
  -- Headless mode
  once_autocmd('VimEnter', nil, function()
    if #vim.api.nvim_list_uis() == 0 then
      vim.schedule(function()
        vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy' })
      end)
    end
  end)
end

function M.report_plugin_load()
  if not stats.start then return end
  local elapsed = math.floor((vim.uv.hrtime() - stats.start) / 1e6 * 100 + 0.5) / 100
  local plugin_dir = vim.fn.stdpath('data') .. '/site/pack/core/opt'
  local total = 0
  if vim.fn.isdirectory(plugin_dir) == 1 then
    local handle = vim.uv.fs_scandir(plugin_dir)
    while handle do
      local name = vim.uv.fs_scandir_next(handle)
      if not name then break end
      total = total + 1
    end
  end
  print(string.format(' 󱐋 %d/%d plugins loaded in %.2f ms',
    stats.loaded, total, elapsed))
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  if vim.fn.argc() ~= 0 then M.config.statistic = false end

  if M.config.statistic then
    stats.start = vim.uv.hrtime()
    stats.cached_rtps = vim.api.nvim_list_runtime_paths()
    vim.schedule(function()
      once_autocmd('User', 'VeryLazy', M.report_plugin_load)
    end)
  end

  if M.config.trigger_verylazy then M.trigger_verylazy() end
end

return M
