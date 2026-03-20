local M = {}

M.is_windows = function()
  return vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1
end

--- check if the current nvim version is compatible with the allowed version
--- @param expected_version string
--- @return boolean
function M.is_compatible_version(expected_version)
  return vim.fn.has(string.format('nvim-%s', expected_version)) == 0
  -- local expect_ver = vim.version.parse(expected_version)
  -- local actual_ver = vim.version()
  -- local result = vim.cmp(expect_ver, actual_ver)
  -- if result ~= 0 then
  --   local _ver = string.format('%s.%s.%s', actual_ver.major, actual_ver.minor, actual_ver.patch)
  --   local msg = string.format(
  --     'Expect nvim version %s, but your current nvim version is %s. Use at your own risk!',
  --     expected_version,
  --     _ver
  --   )
  --   vim.api.nvim_echo({ { msg } }, true, { err = true })
  --   return false
  -- end
  -- return true
end

return M
