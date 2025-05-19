local telescope = {
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			--"BurntSushi/ripgrep",
		},
	},
	--extensions
	{ "nvim-telescope/telescope-file-browser.nvim" },
	{
		"nvim-telescope/telescope-media-files.nvim",
		dependencies = {
			"nvim-lua/popup.nvim",
		},
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
	},
}

return telescope
