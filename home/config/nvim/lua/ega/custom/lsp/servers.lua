local M         = {}

-- Dependencies
local lspconfig = _G.call("lspconfig")
local cmp       = _G.call("cmp_nvim_lsp")
local util      = _G.call("lspconfig.util")

-- Capabilities (guard cmp)
local caps      = (cmp and cmp.default_capabilities())
		or vim.lsp.protocol.make_client_capabilities()
		
-- Load per-language settings (insert only modules that resolved)
local customlsp = require(_G.rprofile .. ".lsp")
local settings  = {}
do
	local names = {
		"lua_ls",
	}
	for _, name in ipairs(names) do
		local mod = _G.call("ega.custom.lsp.settings." .. name)
		if mod then table.insert(settings, mod) end
	end
end


-- normalize: accept list or map
local function as_list(tbl)
	if not tbl then return {} end
	if tbl[1] ~= nil then return tbl end -- already a list
	local out = {}
	for _, v in pairs(tbl) do table.insert(out, v) end
	return out
end

local merged_settings = {}
vim.list_extend(merged_settings, as_list(settings))
vim.list_extend(merged_settings, as_list((customlsp and customlsp.settings) or {}))

function M.get_settings()
	return merged_settings
end

function M.setup()
	if not lspconfig or not util then
		vim.notify("lspconfig/util not available; skipping servers.setup()", vim.log.levels.WARN)
		return
	end
	for _, cfg in ipairs(merged_settings) do
		if cfg and cfg.name and lspconfig[cfg.name] then
			local opts = vim.tbl_deep_extend("force", {}, cfg.opts or {})
			opts.capabilities = caps
			if cfg.root_patterns and util.root_pattern then
				opts.root_dir = util.root_pattern(table.unpack(cfg.root_patterns))
			end
			lspconfig[cfg.name].setup(opts)
		end
	end
end

return M
