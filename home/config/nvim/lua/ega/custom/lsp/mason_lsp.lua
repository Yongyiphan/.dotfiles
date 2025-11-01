local M = {}


function M.setup()
	-- Defer to avoid racing with servers loading
	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			local servers_mod = _G.call("ega.custom.lsp.servers")
			if type(servers_mod) ~= "table" then return end
			local settings = servers_mod.get_settings() or {}
			
			local servers = {}
			for _, cfg in ipairs(settings) do
				if cfg and cfg.name then servers[#servers + 1] = cfg.name end
			end
			
			local mlsp = _G.call("mason-lspconfig")
			if type(mlsp) ~= "table" then return end
			mlsp.setup({ ensure_installed = servers })
		end,
	})
end

return M
