local M = {
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
