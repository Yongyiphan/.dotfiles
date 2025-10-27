local M         = {}

-- Dependencies
local lspconfig = _G.call("lspconfig")
local cmp       = _G.call("cmp_nvim_lsp")
local util      = _G.call("lspconfig.util")

-- Capabilities (guard cmp)
local caps      = (cmp and cmp.default_capabilities())
		or vim.lsp.protocol.make_client_capabilities()
		
-- Load per-language settings (insert only modules that resolved)
local settings  = {}
do
	local names = {
		"ega.custom.lsp.settings.c_cpp",
		"ega.custom.lsp.settings.lua_ls",
		"ega.custom.lsp.settings.python",
		"ega.custom.lsp.settings.cmake",
	}
	for _, name in ipairs(names) do
		local mod = _G.call(name)
		if mod then table.insert(settings, mod) end
	end
end

function M.get_settings()
	return settings
end

function M.setup()
	if not lspconfig or not util then
		vim.notify("lspconfig/util not available; skipping servers.setup()", vim.log.levels.WARN)
		return
	end
	for _, cfg in ipairs(settings) do
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
