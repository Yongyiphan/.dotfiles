local config = require("ega.custom.lsp.lspconfig")
local on_attach = config.on_attach
local capabilities = config.capabilities

local M = {}
M.setup = {
	on_attach = on_attach,
	capabilities = capabilities,
	filetypes = { "python" },
}

local findmypy_config = function()
	local env_name = "env"
	local mypy_config = {
		ini = _G.cwd .. "/mypy.ini",
		py = _G.cwd .. "/" .. env_name .. "/bin/python",
	}
	return mypy_config
end

return M
