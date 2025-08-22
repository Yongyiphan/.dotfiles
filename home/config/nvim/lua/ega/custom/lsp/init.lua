local M = {}

function M.setup()
	local handlers = _G.call("ega.custom.lsp.handlers")
	if not handlers then return end
	handlers.setup()
	local servers_mod = _G.call("ega.custom.lsp.servers")
	if not servers_mod then return end
	servers_mod.setup()
end

return M
