local options = {
	opt = {
		nu = true,
		rnu = true,
		autoindent = true,
		smarttab = true,
		tabstop = 2,
		shiftwidth = 2,
		hlsearch = false,
		incsearch = true,
		ignorecase = true,
		smartcase = true,
		scrolloff = 8,
		showcmd = true,
		mouse = "a",
		title = true,
		clipboard = "unnamedplus",
		backspace = "indent,eol,start",
		splitright = true,
		splitbelow = true,
		encoding = "utf-8",
		termguicolors = true,
	},
}

-- vim.cmd([[set guicursor=n-v-i-c:block-Cursor/lCursor]])
vim.g.toggleterm_terminal_mappings = 0
vim.lsp.set_log_level("error")
vim.o.signcolumn = "yes"
vim.opt.termguicolors = true
require("vim.lsp.log").set_format_func(vim.inspect)
for scope, table in pairs(options) do
	for setting, value in pairs(table) do
		vim[scope][setting] = value
	end
end
