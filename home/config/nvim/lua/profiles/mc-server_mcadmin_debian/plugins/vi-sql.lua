return {
	{
		"kopecmaciej/vi-sql.nvim",
		cmd = { "ViSQL", "ViSQLJump" },
		keys = {
			{ "<leader>vs", "<cmd>ViSQL<cr>", desc = "Open vi-sql", silent = true },
		},
		config = function()
			-- vi-sql connection targets are passed when the app launches, not in setup().
			-- Examples from the author:
			--   vi-sql --connect main=file:/absolute/path/to/db.sqlite
			--   vi-sql --connect main=sqlite:///absolute/path/to/db.sqlite
			-- App-level keybindings live under ~/.config/vi-sql/.
			require("vi-sql").setup({
				hide_key = "<C-q>",
			})
		end,
	},
}
