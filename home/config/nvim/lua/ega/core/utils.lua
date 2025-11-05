local M = {}
_G.plugins = {}

function _G.call(plugin)
  -- Try to require the module
  local ok, result = pcall(require, plugin)
  -- Always capture the caller’s location
  local info = debug.getinfo(2, "Sl")
  local base = vim.fn.stdpath("config") .. "/"
  local src  = info.short_src:gsub("^" .. vim.pesc(base), "")
  local line = info.currentline

  if not ok then
    _G.Setup_Status = false
    -- Print a clear error with location
    vim.notify(
      string.format(
        "Failed to load module '%s' at %s:%d\n%s",
        plugin, src, line, result
      ),
      vim.log.levels.ERROR
    )
    return nil
  end
	if result == true then return nil end

  if _G.Core.LoadUpMsg then
    vim.notify(
      string.format(
        "Loaded module '%s' from %s:%d",
        plugin, src, line
      ),
      vim.log.levels.INFO
    )
  end

  -- Cache and return
  _G.plugins = _G.plugins or {}
  _G.plugins[plugin] = result
  return result
end

_G.KeyOpts = function(desc, opts)
	opts = opts or {
		noremap = true,
		silent = true,
		desc = "",
	}
	opts.desc = desc
	return opts
end

_G.adjust_width = function(delta)
	vim.cmd('vertical resize ' .. delta)
end

M.CurrentLoc = function()
	print(vim.fn.expand("%:p"))
end

M.convert_path_to_windows = function(path)
	-- Replace /mnt/c with C:\
	if string.sub(path, 1, 6) == "/mnt/c" then
		path = string.gsub(path, "^/mnt/(%w)/", "%1:/")
		-- Replace remaining forward slashes with backslashes
		path = string.gsub(path, "/", "\\\\")
		return path
	end
	return false
end


return M
