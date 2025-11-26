-- Unused for now
local M = {}

M.languages = vim.list_extend(
	vim.deepcopy(require("profiles.default.lsp").languages),
	{
		"c_cpp",
		"python",
		"cmake",
	}
)


return M
