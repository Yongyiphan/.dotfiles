local M = {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
		config = function()
			require("ega.custom.treesitter").setup()
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
