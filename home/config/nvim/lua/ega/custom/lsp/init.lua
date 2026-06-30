local M = {}

function M.setup()
	require("ega.custom.lsp.boot")
	require("ega.custom.lsp.format")
end

M.setup()
local utils = require("ega.custom.lsp.utils")
M.utils = utils
return M
