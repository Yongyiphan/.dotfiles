local M = {}

function M.setup()
	local mason = _G.call("mason")
	if type(mason) == "table" then mason.setup() end
end

function M.setup_installer()
	-- Defer to after UI to avoid startup races
	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			local servers_mod = _G.call("ega.custom.lsp.servers")
			if type(servers_mod) ~= "table" then return end
			local settings = servers_mod.get_settings() or {}
			
			local tools = {}
			for _, cfg in ipairs(settings) do
				for _, t in ipairs(cfg.tools or {}) do tools[#tools + 1] = t end
			end
			-- dedupe if/when you re-enable mason-tool-installer
			-- local seen, list = {}, {}
			-- for _, t in ipairs(tools) do
			--   if not seen[t] then seen[t] = true; list[#list + 1] = t end
			-- end
			-- local installer = _G.call("mason-tool-installer")
			-- if installer then
			--   installer.setup({
			--     ensure_installed = list,
			--     auto_update      = true,
			--     run_on_start     = true,
			--   })
			-- end
		end,
	})
end

return M
