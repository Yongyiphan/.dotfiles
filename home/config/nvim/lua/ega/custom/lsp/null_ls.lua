local M = {}

function M.setup()
	local null_ls = _G.call("null-ls")
	if not null_ls then return end
	local aug         = vim.api.nvim_create_augroup("NullLsFormatting", {})
	
	local servers_mod = _G.call("ega.custom.lsp.servers")
	if not servers_mod then return end
	local settings = servers_mod.get_settings()
	local sources  = {}
	
	for _, cfg in ipairs(settings) do
		for _, method in ipairs(cfg.null_ls.formatting or {}) do
			local src = null_ls.builtins.formatting[method]
			if src then table.insert(sources, src) end
		end
		for _, method in ipairs(cfg.null_ls.diagnostics or {}) do
			local src = null_ls.builtins.diagnostics[method]
			if src then table.insert(sources, src) end
		end
	end
	
	null_ls.setup({
		sources = sources,
		on_attach = function(client, bufnr)
			if client.supports_method("textDocument/formatting") then
				vim.api.nvim_clear_autocmds({ group = aug, buffer = bufnr })
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = aug,
					buffer = bufnr,
					callback = function() vim.lsp.buf.format({ bufnr = bufnr }) end,
				})
			end
		end,
	})
end

return M

