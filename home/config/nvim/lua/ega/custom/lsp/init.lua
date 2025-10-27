local M = {}

local function is_table(x) return type(x) == "table" end

function M.setup()
	local handlers = _G.call("ega.custom.lsp.handlers")
	if is_table(handlers) and handlers.setup then
		pcall(handlers.setup)
	end
	
	-- Defer to avoid racing with plugin load order
	vim.schedule(function()
		local servers_mod = _G.call("ega.custom.lsp.servers")
		if is_table(servers_mod) and servers_mod.setup then
			pcall(servers_mod.setup)
		end
		
		local nulls = _G.call("ega.custom.lsp.null_ls")
		if is_table(nulls) and nulls.setup then
			pcall(nulls.setup)
		end
	end)
end

M.setup()
M.utils = require("ega.custom.lsp.utils")

return M
