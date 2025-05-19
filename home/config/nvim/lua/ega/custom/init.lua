local M = {}
M.autocmp = require("ega.custom.autocmp")
M.buffer = require("ega.custom.buffer")
M.cs = require("ega.custom.cheatsheet")
M.git = require("ega.custom.git")
M.fugitive = require("ega.custom.fugitive")
M.fzflua = require("ega.custom.fzflua")
M.lsp = require("ega.custom.lsp")
M.ts = require("ega.custom.treesitter")
M.term = require("ega.custom.toggleterm")
M.statusline = require("ega.custom.statusline")
M.telescope = require("ega.custom.telescope")
M.dap = require("ega.custom.dap")
M.config = require("ega.custom.nvim_config")
M.diagnostics = require("ega.custom.diagnostics")

M.custom_setup = function()
	require("nvim-web-devicons").setup()
end

return M
