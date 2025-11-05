local M = {}

if vim.g._none_ls_setup_done then
	return M
end
 print("null_ls")

function M.setup()
	local null_ls = _G.call("null-ls")
	local builtins = null_ls.builtins
	local aug = vim.api.nvim_create_augroup("NoneLsFormatting", { clear = true })
	
	local servers_mod = _G.call("ega.custom.lsp.servers")
	if not servers_mod or not servers_mod.get_settings then
		return
	end
	
	local settings = servers_mod.get_settings()
	local sources, unknown = {}, {}
	
	local function add(kind, name)
		local src = kind and kind[name]
		if src then
			table.insert(sources, src)
		else
			table.insert(unknown, name)
		end
	end
	
	for _, cfg in ipairs(settings) do
		for _, n in ipairs((cfg.null_ls and cfg.null_ls.formatting) or {}) do
			add(builtins.formatting, n)
		end
		for _, n in ipairs((cfg.null_ls and cfg.null_ls.diagnostics) or {}) do
			add(builtins.diagnostics, n)
		end
	end
	
	if #unknown > 0 then
		vim.schedule(function()
			vim.notify("[null-ls] Unknown builtins: " .. table.concat(unknown, ", "), vim.log.levels.WARN)
		end)
	end
	
	null_ls.setup({
		sources = sources,
		on_attach = function(client, bufnr)
			if client.supports_method("textDocument/formatting") then
				vim.api.nvim_clear_autocmds({ group = aug, buffer = bufnr })
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = aug,
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.format({
							bufnr = bufnr,
							async = false,
							filter = function(c)
								return c.name == "null-ls"
							end,
						})
					end,
				})
			end
		end,
	})
	
	vim.g._none_ls_setup_done = true
end

return M
