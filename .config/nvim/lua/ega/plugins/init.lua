local core_plugins = {
	{ "tpope/vim-fugitive" },
	{ "tpope/vim-rhubarb" },
	{ "tpope/vim-surround" },
	{ "inkarkat/vim-ReplaceWithRegister" },
	--tmux & split window navigation
	{ "christoomey/vim-tmux-navigator" },
	--maximizes and restore current window
	{ "szw/vim-maximizer" },
	{ "numToStr/Comment.nvim" },
	{ "nvim-tree/nvim-web-devicons" },
	--Auto closing
	{ "windwp/nvim-autopairs" },
	--snippets
	{
		"L3MON4D3/Luasnip",
		version = "v2.*",
		build = "make install_jsregexp"
	},
	{ "saadparwaiz1/cmp_luasnip" }, -- for autocompletion
	{ "rafamadriz/friendly-snippets" },
	{
		"folke/which-key.nvim",
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 200
			require("which-key").setup({
				icons = {
					group = "",
				},
			})
		end,
	},
	{ "EdenEast/nightfox.nvim" },
	--toggle terminal
	{ "akinsho/toggleterm.nvim", version = "*", config = true },
}

return core_plugins
