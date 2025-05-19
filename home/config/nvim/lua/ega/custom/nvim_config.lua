local M = {}

M.edit_nvim = function()
	require("telescope.builtin").find_files({
		cwd = "~/.config/nvim",
	})
end

M.save_source = function()
	local config_dir = os.getenv("HOME") .. "/.config"
	local current_file = vim.fn.expand("%:p")
	local filetype = vim.fn.fnamemodify(current_file, ":e")
	if string.find(current_file, config_dir) and filetype == "lua" then
		vim.cmd("w " .. current_file)
		vim.cmd("luafile " .. current_file)
		print("Sourced " .. current_file)
	else
		print("Not a .config lua file")
	end
end

M.reload_config = function()
	for name, _ in ipairs(package.loaded) do
		if name:match("^ega") then
			package.loaded[name] = nil
			print(name)
		end
	end
	dofile(vim.env.MYVIMRC)
	vim.notify("Reload T Nvim Config!", vim.log.levels.INFO)
end

M.yankall = function()
	vim.cmd("ggvGy")
end
local ctele = require("ega.custom.telescope")
local core_files_dir = "~/.config/nvim"
local share_files_dir = vim.fn.fnamemodify(vim.fn.stdpath("data"), ":h")

M.t_core_files = function()
	ctele.t_find_files(core_files_dir)
end
M.t_share_files = function()
	local opts = {
		hidden = true,
		no_ignore = true,
	}
	ctele.t_find_files(share_files_dir, opts)
end
M.b_core_files = function()
	ctele.file_explorer(core_files_dir)
end
M.b_share_files = function()
	ctele.file_explorer(share_files_dir)
end
return M
