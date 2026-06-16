local M = {}

function M.is_windows()
  -- return vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1
  return jit.os == 'Windows'
end

--- Check if the current nvim version is compatible with the allowed version
--- @param version string
--- @return boolean
function M.is_compatible_version(version)
  -- Old method
  -- return vim.fn.has(string.format('nvim-%s', expected_version)) == 0
  -- New method
  -- https://neovim.io/doc/user/lua/#vim.version.le()
  return vim.version.le(vim.version(), version)
end

-- Calc last time ago
function M.time_ago(time)
  local diff = math.max(0, os.time() - time)
  if diff < 60 then return 'just now' end
  local mins = math.floor(diff / 60)
  if mins < 60 then return mins .. (mins == 1 and ' min ago' or ' mins ago') end
  local hours = math.floor(mins / 60)
  if hours < 24 then return hours .. (hours == 1 and ' hr ago' or ' hrs ago') end
  local days = math.floor(hours / 24)
  if days < 30 then return days .. (days == 1 and ' day ago' or ' days ago') end
  local months = math.floor(days / 30)
  if months < 12 then return months .. (months == 1 and ' mo ago' or ' mos ago') end
  local years = math.floor(days / 365.25)
  return years .. (years == 1 and ' yr ago' or ' yrs ago')
end

return M
