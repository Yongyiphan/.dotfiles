local Languages = _G.call("ega.plugins.lspLang")
local P = {
	-- Mason core installer
	{
		"williamboman/mason.nvim",
		cmd    = { "Mason", "MasonInstall", "MasonUpdate" },
		build  = ":MasonUpdate",
		event = "VeryLazy",
		config = function()
			local ok, mason = pcall(require, "mason")
			if ok then mason.setup({}) end
		end,
	},
	-- Mason tool installer (servers + CLI tools)
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		after = "mason.nvim",
	},
	-- Bridge Mason → LSPConfig
	{
		"williamboman/mason-lspconfig.nvim",
		after = { "mason.nvim", "mason-tool-installer.nvim" },
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
	{ 
		"zbirenbaum/copilot.lua",
		lazy = false,  -- load early, before cmp
		config = function()
			require("copilot").setup({
				suggestion = {
					enabled = true,
					auto_trigger = true,     -- show ghost text automatically
					keymap = {
						accept = "<C-l>",      -- avoid <Tab> conflict with your cmp/snippets
						next   = "<M-]>",
						prev   = "<M-[>",
						dismiss= "<C-]>",
					},
				},
				panel = { enabled = false },
				filetypes = {
					["*"] = true,            -- enable everywhere; tighten later if you want
				},
			})
		end,
	},
	{ 
		"zbirenbaum/copilot-cmp",
		dependencies = 
		{
			"zbirenbaum/copilot.lua"
		}, 
		config = function()
			require("copilot_cmp").setup()
		end 
	},
	-- none-ls for formatting & diagnostics
	{
		"nvimtools/none-ls.nvim",
		after        = "mason-lspconfig.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = {"BufReadPre", "BufNewFile", "BufReadPost"}
	},
	-- Avante deps (recommended by Avante)
	{
		"MunifTanjim/nui.nvim",
		lazy = true,
	},
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
	},

	-- Avante (codebase/chat sidebar)
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false, -- Avante recommends never setting "*"
		build = vim.fn.has("win32") ~= 0
				and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
				or "make",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
			"hrsh7th/nvim-cmp",
			"zbirenbaum/copilot.lua", -- provider='copilot'
			-- optional pickers (install only if you use them)
			-- "nvim-telescope/telescope.nvim",
			-- "ibhagwan/fzf-lua",
			-- "nvim-mini/mini.pick",
			-- optional input UI
			-- "stevearc/dressing.nvim",
			-- "folke/snacks.nvim",
		},
		opts = {
			instructions_file = "avante.md",
			provider = "copilot",

			-- you said you do not care about inline suggestions
			behaviour = {
				auto_suggestions = false,
			},
		},
		keys = {
			{ "<leader>aa", "<cmd>AvanteAsk<cr>",    desc = "Avante: Ask" },
			{ "<leader>ac", "<cmd>AvanteChat<cr>",   desc = "Avante: Chat" },
			{ "<leader>at", "<cmd>AvanteToggle<cr>", desc = "Avante: Toggle sidebar" },
			{ "<leader>am", "<cmd>AvanteShowRepoMap<cr>", desc = "Avante: Repo map" },
		},
	},

	Languages
}

return P
