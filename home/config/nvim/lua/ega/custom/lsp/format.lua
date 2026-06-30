-- lua/ega/custom/lsp/format.lua
local grp = vim.api.nvim_create_augroup("EgaFormatOnSaveGlobal", { clear = true })

local function is_none_ls_client(client)
	return client.supports_method("textDocument/formatting")
		and (client.name == "null-ls" or client.name == "none-ls")
end

vim.api.nvim_create_autocmd("BufWritePre", {
	group = grp,
	callback = function(args)
		-- If the pipeline attached a local formatter, skip the global one
		if vim.b[args.buf] and vim.b[args.buf].ega_local_format then return end
		
		-- Prefer null/none-ls if present and can format; else fall back
		local has_none = false
		for _, c in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
			if is_none_ls_client(c) then
				has_none = true
				break
			end
		end
		
		if has_none then
			vim.lsp.buf.format({
				bufnr = args.buf,
				async = false,
				timeout_ms = 3000,
				filter = is_none_ls_client,
			})
		else
			vim.lsp.buf.format({ bufnr = args.buf, async = false, timeout_ms = 3000 })
		end
	end,
})
