-- lua/ega/custom/lsp/format.lua
local grp = vim.api.nvim_create_augroup("EgaFormatOnSaveGlobal", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
	group = grp,
	callback = function(args)
		-- If the pipeline attached a local formatter, skip the global one
		if vim.b[args.buf] and vim.b[args.buf].ega_local_format then return end
		
		-- Prefer null/none-ls if present and can format; else fall back
		local has_none = false
		for _, c in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
			if c.supports_method("textDocument/formatting")
					and (c.name == "null-ls" or c.name == "none-ls") then
				has_none = true
				break
			end
		end
		
		if has_none then
			vim.lsp.buf.format({ bufnr = args.buf, async = false, name = "null-ls", timeout_ms = 3000 })
		else
			vim.lsp.buf.format({ bufnr = args.buf, async = false, timeout_ms = 3000 })
		end
	end,
})
