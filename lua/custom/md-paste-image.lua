local M = {
  opts = {
    img_dir = 'img/%:t:r',
    filetypes = { 'markdown', 'markdownx' },
    img_name = nil,
    drag_and_drop = true,
  },
}

local uv = vim.uv
local original_paste

local image_exts = {
  png = true,
  jpg = true,
  jpeg = true,
  gif = true,
  webp = true,
  bmp = true,
  tif = true,
  tiff = true,
  svg = true,
}

local function enabled()
  return vim.tbl_contains(M.opts.filetypes, vim.bo.filetype)
end

local function get_os()
  if vim.fn.has('win32') == 1 then
    return 'Windows'
  end

  local f = io.popen('uname')
  if not f then
    return
  end

  local name = vim.trim(f:read('*a'))
  f:close()
  if name == 'Linux' then
    local version = vim.fn.readfile('/proc/version')[1] or ''

    if version:lower():match('microsoft') then
      return 'Wsl'
    end
  end

  return name
end

local function get_commands(os_name)
  if os_name == 'Windows' or os_name == 'Wsl' then
    local check = 'Get-Clipboard -Format Image'

    return {
      check = 'powershell.exe "' .. check .. '"',
      save = 'powershell.exe "$content = ' .. check
        .. ";$content.Save('%s', 'png')\"",
    }
  end

  if os_name == 'Darwin' then
    return {
      check = 'pngpaste -b 2>&1',
      save = "pngpaste '%s'",
    }
  end

  if os_name == 'Linux' then
    if vim.env.XDG_SESSION_TYPE == 'wayland' then
      return {
        check = 'wl-paste --list-types',
        save = "wl-paste --no-newline --type image/png > '%s'",
      }
    end

    return {
      check = 'xclip -selection clipboard -o -t TARGETS',
      save = "xclip -selection clipboard -t image/png -o > '%s'",
    }
  end
end

local function expand_dir()
  local dir = vim.fn.expand(M.opts.img_dir or '')
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= '' then
    dir = dir:gsub('%%(:[^/\\]+)', function(mod)
      return vim.fn.fnamemodify(file, mod)
    end)
  end

  return dir
end

local function image_path(name)
  local dir = expand_dir()

  if dir == '' then return name end

  vim.fn.mkdir(dir, 'p')
  return dir .. '/' .. name
end

local function insert(path)
  local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
  local text = '![](' .. path .. ')'
  local line = vim.api.nvim_get_current_line()

  vim.api.nvim_set_current_line(
    line:sub(1, col) .. text .. line:sub(col + 1)
  )

  vim.api.nvim_win_set_cursor(0, {
    row,
    col + #text,
  })
end

function M.paste_img()
  if not enabled() then return end

  local os_name = get_os()
  local cmd = get_commands(os_name)
  if not cmd then
    vim.notify('clipboard-image: unsupported clipboard', vim.log.levels.ERROR)
    return
  end

  local f = io.popen(cmd.check)
  if not f then
    vim.notify('clipboard-image: failed to access clipboard', vim.log.levels.ERROR)
    return
  end

  local content = f:read('*a') or ''
  f:close()

  local has_image =
    os_name == 'Windows'
    or os_name == 'Wsl'
    or content:find('image/png', 1, true)
    or (
      os_name == 'Darwin'
      and content:sub(1, 9) == 'iVBORw0KG'
    )
  if not has_image then
    vim.notify('clipboard-image: no image in clipboard', vim.log.levels.WARN)
    return
  end

  local name = tostring(
    M.opts.img_name or os.date('%Y-%m-%d-%H-%M-%S')
  ):gsub('%.png$', '') .. '.png'
  local path = image_path(name)
  if os.execute(string.format(cmd.save, path)) ~= true
    and vim.v.shell_error ~= 0 then
    vim.notify('clipboard-image: failed to save image', vim.log.levels.ERROR)
    return
  end

  if vim.fn.filereadable(path) == 0 then
    vim.notify('clipboard-image: image was not saved', vim.log.levels.ERROR)
    return
  end

  insert(path)
end

local function normalize(path)
  path = vim.trim(path)
    :gsub('^"(.*)"$', '%1')
    :gsub("^'(.*)'$", '%1')

  if vim.fn.has('win32') == 1 then
    local drive, rest = path:match('^/([a-zA-Z])/(.*)$')

    if drive then
      path = drive:upper() .. ':/' .. rest
    end

    path = path:gsub('\\', '/')
  end

  return vim.fn.fnamemodify(path, ':p')
end

function M.drop_img(raw_path)
  if not enabled() then
    return false
  end

  local path = normalize(raw_path)
  local ext = vim.fn.fnamemodify(path, ':e'):lower()
  if not image_exts[ext]
    or vim.fn.filereadable(path) == 0 then
    return false
  end

  local target = image_path(
    vim.fn.fnamemodify(path, ':t')
  )

  if vim.fn.fnamemodify(path, ':p')
    ~= vim.fn.fnamemodify(target, ':p') then
    local ok, err = uv.fs_copyfile(path, target)

    if not ok then
      vim.notify('clipboard-image: failed to copy image\n' .. tostring(err),
        vim.log.levels.ERROR
      )
      return true
    end
  end

  insert(target)
  return true
end

local function setup_drag()
  if original_paste then
    return
  end

  original_paste = vim.paste

  vim.paste = function(lines, phase)
    if phase == -1 and #lines == 1
      and M.drop_img(lines[1]) then
      return
    end

    return original_paste(lines, phase)
  end
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend(
    'force',
    M.opts,
    opts or {}
  )

  if M.opts.drag_and_drop then
    setup_drag()
  end

  vim.keymap.set('n', '<leader>pi', M.paste_img, {
    silent = true,
    desc = 'Paste image',
  })
end

return M
