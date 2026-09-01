local M = {
  opts = {
    img_dir = 'img',
    filetypes = { 'markdown', 'markdownx' },
    img_name = nil,
    auto_paste = false,
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

local function normalize_path(path)
  path = vim.trim(path)
  path = path:gsub('^"(.*)"$', '%1')
  path = path:gsub("^'(.*)'$", '%1')

  if vim.fn.has('win32') == 1 then
    local drive, rest = path:match('^/([a-zA-Z])/(.*)$')

    if drive then
      path = drive:upper() .. ':/' .. rest
    end

    path = path:gsub('\\', '/')
  end

  return vim.fn.fnamemodify(path, ':p')
end

local function insert_image(path)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local text = '![](' .. path .. ')'

  vim.api.nvim_set_current_line(
    line:sub(1, cursor[2]) .. text .. line:sub(cursor[2] + 1)
  )

  vim.api.nvim_win_set_cursor(0, {
    cursor[1],
    cursor[2] + #text,
  })
end

local function image_path(name)
  local dir = vim.fn.expand(M.opts.img_dir)

  if dir == '' then
    return name
  end

  vim.fn.mkdir(dir, 'p')
  return dir .. '/' .. name
end

local function clipboard_commands()
  if vim.fn.has('win32') == 1 then
    local check = 'Get-Clipboard -Format Image'

    return {
      check = 'powershell.exe "' .. check .. '"',
      save = 'powershell.exe "$content = ' .. check
        .. ";$content.Save('%s', 'png')\"",
    }
  end

  local handle = io.popen('uname')
  if not handle then
    return
  end

  local os = vim.trim(handle:read('*a'))
  handle:close()

  if os == 'Linux' then
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

  if os == 'Darwin' then
    return {
      check = 'pngpaste -b 2>&1',
      save = "pngpaste '%s'",
    }
  end
end

function M.paste_img()
  if not enabled() then
    return
  end

  local commands = clipboard_commands()

  if not commands then
    vim.notify('clipboard-image: unsupported clipboard', vim.log.levels.ERROR)
    return
  end

  local handle = io.popen(commands.check)

  if not handle then
    vim.notify(
      'clipboard-image: failed to access clipboard',
      vim.log.levels.ERROR
    )
    return
  end

  local content = handle:read('*a')
  handle:close()

  local has_image = vim.fn.has('win32') == 1
    or content:find('image/png', 1, true)
    or (
      vim.fn.has('mac') == 1
      and content:sub(1, 9) == 'iVBORw0KG'
    )

  if not has_image then
    vim.notify('There is no image data in clipboard', vim.log.levels.ERROR)
    return
  end

  local name = M.opts.img_name or os.date('%Y-%m-%d-%H-%M-%S')
  local path = image_path(name .. '.png')
  local result = vim.fn.system(string.format(commands.save, path))

  if vim.v.shell_error ~= 0 then
    vim.notify(
      'clipboard-image: failed to save image\n' .. result,
      vim.log.levels.ERROR
    )
    return
  end

  insert_image(path)
end

function M.drop_img(raw_path)
  if not enabled() then
    return false
  end

  local path = normalize_path(raw_path)
  local ext = vim.fn.fnamemodify(path, ':e'):lower()

  if not image_exts[ext] or not vim.fn.filereadable(path) then
    return false
  end

  local name = vim.fn.fnamemodify(path, ':t')
  local target = image_path(name)

  if vim.fn.fnamemodify(path, ':p') ~= vim.fn.fnamemodify(target, ':p') then
    local ok, err = uv.fs_copyfile(path, target)

    if not ok then
      vim.notify(
        'clipboard-image: failed to copy image\n' .. tostring(err),
        vim.log.levels.ERROR
      )
      return true
    end
  end

  insert_image(target)
  return true
end

local function setup_paste()
  if original_paste then
    return
  end

  original_paste = vim.paste

  vim.paste = function(lines, phase)
    if phase == -1 and #lines == 1 and #lines[1] <= 4096 then
      if M.drop_img(lines[1]) then
        return
      end
    end

    return original_paste(lines, phase)
  end
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})

  if M.opts.drag_and_drop then
    setup_paste()
  end

  if M.opts.auto_paste then
    vim.api.nvim_create_autocmd('FileType', {
      pattern = M.opts.filetypes,
      callback = function(args)
        vim.keymap.set('n', 'p', M.paste_img, {
          buffer = args.buf,
          silent = true,
          desc = 'Paste image',
        })
      end,
    })
  else
    vim.keymap.set('n', '<leader>pi', M.paste_img, {
      silent = true,
      desc = 'Paste image',
    })
  end
end

return M
