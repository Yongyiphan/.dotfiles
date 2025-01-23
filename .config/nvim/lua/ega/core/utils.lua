local M = {}
_G.plugins = {}

function _G.call(plugin)
	-- if _G.plugins[plugin] ~= nil then
	-- 	return _G.plugins[plugin]
	-- else
	local plugin_status, result = pcall(require, plugin)
	if _G.Core.LoadUpMsg then
		local info = debug.getinfo(2, "Sl")
		local base_path = vim.fn.stdpath("config") .. "/"
		local relative_path = info.short_src:gsub("^" .. base_path, "")
		vim.notify(
			"Loading plugin: " .. plugin ..
			" from file: " .. relative_path ..
			" on line: " .. info.currentline)
	end
	if not plugin_status then
		_G.Setup_Status = false
		print("Fail to call " .. plugin)
		if _G.Core.LoadUpMsg then
			print(debug.traceback())
		end
		return plugin_status
	end
	_G.plugins[plugin] = result
	return result
	-- end
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
