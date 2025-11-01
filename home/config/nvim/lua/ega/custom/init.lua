local M = {}
M.dap = require("ega.custom.dap")
M.lsp = require("ega.custom.lsp")
M.buffer = require("ega.custom.buffer")
M.cs = require("ega.custom.cheatsheet")
M.git = require("ega.custom.git")
M.fugitive = require("ega.custom.fugitive")
M.fzflua = require("ega.custom.fzflua")
M.term = require("ega.custom.toggleterm")
M.statusline = require("ega.custom.statusline")
M.telescope = require("ega.custom.telescope")
M.config = require("ega.custom.nvim_config")
M.diagnostics = require("ega.custom.diagnostics")
M.none_ls = require("ega.custom.none-ls")

M.custom_setup = function()
	require("nvim-web-devicons").setup()
end

return M
