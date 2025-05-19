local M = {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = function()
			local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
			ts_update()
		end,
	},
	{
		"numirias/semshi",
		build = function()
			pcall(vim.cmd, "UpdateRemotePlugins")
		end,
	},
}
return M
