local M = {
	--Python debugger
	{
		"mfussenegger/nvim-dap-python",
		ft = "python",
		dependencies = {
			"mfussenegger/nvim-dap",
			"rcarriga/nvim-dap-ui",
		},
	},
	-- For lazy.nvim
	{
		'MeanderingProgrammer/markdown.nvim',
		name = 'render-markdown',
		dependencies = {
			'nvim-treesitter/nvim-treesitter',
			'echasnovski/mini.icons', -- or 'nvim-tree/nvim-web-devicons'
		},
		config = function()
			require('render-markdown').setup({
				file_types = { "markdown", "vimwiki" },
			})
		end,
	},
}

return M
