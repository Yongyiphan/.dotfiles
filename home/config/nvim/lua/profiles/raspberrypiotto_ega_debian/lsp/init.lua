local M = {}

M.languages = vim.list_extend(
	vim.deepcopy(require("profiles.default.lsp").languages),
	{
		"python",
		"typescript",
	}
)


return M
