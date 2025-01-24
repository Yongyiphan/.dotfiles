local toggleterm = _G.call("toggleterm")
if not toggleterm then
	return
end
local M = {}

local Terminal = require("toggleterm.terminal").Terminal
M.cheatsheet = Terminal:new({
	cmd = "navi fn welcome",
	direction = "float",
	hidden = true,
	float_opts = {
		border = "double",
	},
	on_open = function(term)
		vim.cmd("startinsert!")
		vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<cr>", { noremap = true, silent = true })
		vim.api.nvim_buf_set_keymap(0, "t", "<esc>", "<cmd>close<CR>", { silent = false, noremap = true })
		if vim.fn.mapcheck("<esc>", "t") ~= "" then
			vim.api.nvim_buf_del_keymap(term.bufnr, "t", "<esc>")
		end
	end,
	on_close = function(term)
		vim.cmd("startinsert!")
	end,
	close_on_exit = false,
})

function M.cheatsheet_toggle()
	M.cheatsheet:toggle()
end

return M
