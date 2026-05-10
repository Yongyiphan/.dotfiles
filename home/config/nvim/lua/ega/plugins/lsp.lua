local P = {
	-- Mason core installer
	{
		"mason-org/mason.nvim",
		build = ":MasonUpdate",
		lazy = false,
		opts = {},
	},
	-- Mason tool installer (servers + CLI tools)
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
	},
	-- Bridge Mason → LSPConfig
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		opts = {
			automatic_enable = false,
		},
	},
	-- Core LSP client
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local init = _G.call("ega.custom.lsp")
			if not init then return end
			init.setup()
		end,
	},
	-- Completion + snippets
	{
		"hrsh7th/nvim-cmp",
		event        = "InsertEnter",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"windwp/nvim-autopairs",
		},
		config       = function()
			local cmp_mod = _G.call("ega.custom.autocmp")
			if not cmp_mod then return end
			cmp_mod.setup()
		end,
	},
	{
			"hrsh7th/cmp-nvim-lsp",
			lazy = false,
	},
	-- none-ls repo for formatting & diagnostics.
	-- Runtime API remains `require("null-ls")`.
	{
		"nvimtools/none-ls.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "mason-org/mason-lspconfig.nvim" },
		event = {"BufReadPre", "BufNewFile", "BufReadPost"}
	},
	{
		"MunifTanjim/nui.nvim",
		lazy = true,
	},
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
	},
}

return P
