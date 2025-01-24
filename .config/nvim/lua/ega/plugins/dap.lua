local M = {
	{
		"mfussenegger/nvim-dap",
		event = "VeryLazy",
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio"
		},
	},
	{
		"nvim-telescope/telescope-dap.nvim",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-telescope/telescope.nvim",
			"williamboman/mason.nvim",
		},
	},
	{ "theHamsta/nvim-dap-virtual-text" },
	{ "jbyuki/one-small-step-for-vimkind" },
	{ "jay-babu/mason-nvim-dap.nvim" },
	--Protocols
	--Python debugger
	{
		"mfussenegger/nvim-dap-python",
		ft = "python",
		dependencies = {
			"mfussenegger/nvim-dap",
			"rcarriga/nvim-dap-ui",
		},
	},
}


return M
