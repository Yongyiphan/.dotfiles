local telescope = _G.call("telescope")
if not telescope then
	return
end
local telebuiltin = require("telescope.builtin")

local toggleterm = _G.call("toggleterm")
if not toggleterm then
	return
end

local M = {}
local Terminal = require("toggleterm.terminal").Terminal
M.lazygit = Terminal:new({
	cmd = "lazygit",
	direction = "float",
	hidden = true,
	count = 2,
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
})

function M._lazygit_toggle()
	M.lazygit:toggle()
end

function M.G_git_files()
	telebuiltin.git_files()
end

return M
