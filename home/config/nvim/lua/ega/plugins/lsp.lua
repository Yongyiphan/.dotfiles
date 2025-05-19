local Languages = require("ega.plugins.lspLang")
local P = {
	{ "neovim/nvim-lspconfig" },
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		cmd = { "Mason", "MasonInstall", "MasonUpdate" },
		dependencies = {
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
	},
	{ "williamboman/mason-lspconfig.nvim" }, -- Optional
	{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
	--Auto Completion
	{ "hrsh7th/nvim-cmp" },
	{ "hrsh7th/cmp-buffer" },
	{ "hrsh7th/cmp-path" },
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/cmp-nvim-lsp-signature-help" },
	--C++ extensions
	{ "p00f/clangd_extensions.nvim" },
	{ "microsoft/vscode-codicons" },
	-- --formatting & linting
	-- { "jose-elias-alvarez/null-ls.nvim" }, -- configure formatters & linters
	-- {
	-- 	"jayp0521/mason-null-ls.nvim",
	-- 	event = { "BufReadPre", "BufNewFile" },
	-- 	dependencies = {
	-- 		"williamboman/mason.nvim",
	-- 		"jose-elias-alvarez/null-ls.nvim",
	-- 	},
	-- }, -- bridges gap b/w mason & null-ls
	{
		"nvimtools/none-ls.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim"
		}
	}, -- configure formatters & linters
	{
		"jayp0521/mason-null-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"nvimtools/none-ls.nvim",
		},
	}, -- bridges gap b/w mason & null-ls
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
	},
	Languages
}

return P
