local M = {}
local lspconfig = _G.call("lspconfig")
if not lspconfig then return M end
local caps = _G.call("cmp_nvim_lsp").default_capabilities()

-- pull in util here, at setup time
local util = _G.call("lspconfig.util")
if not util then return end

-- Load per-language settings
local settings = {
	_G.call("ega.custom.lsp.settings.c_cpp"),
	_G.call("ega.custom.lsp.settings.lua_ls"),
	_G.call("ega.custom.lsp.settings.python"),
	_G.call("ega.custom.lsp.settings.cmake"),
}

function M.get_settings()
	return settings
end

function M.setup()
	for _, cfg in ipairs(settings) do
		if cfg and cfg.name then
			local opts = cfg.opts or {}
			opts.capabilities = caps
			-- now apply root_dir if provided
			if cfg.root_patterns then
				opts.root_dir = util.root_pattern(table.unpack(cfg.root_patterns))
			end
			lspconfig[cfg.name].setup(opts)
		end
	end
end

return M
