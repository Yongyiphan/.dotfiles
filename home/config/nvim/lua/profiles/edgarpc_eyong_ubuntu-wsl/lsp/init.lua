-- Unused for now
local M = {}

M.languages = vim.list_extend(
	vim.deepcopy(require("profiles.default.lsp").languages),
	{
		"python",
		"typescript",
		"markdown"
		-- "json",
		-- "yaml",
	}
)


return M
