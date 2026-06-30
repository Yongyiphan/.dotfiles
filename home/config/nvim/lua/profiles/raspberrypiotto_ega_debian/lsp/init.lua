local M = {}

M.languages = vim.list_extend(
	vim.deepcopy(require("profiles.default.lsp").languages),
	{
		"python",
		"typescript",
	}
)

M.enable_avante = false


return M
