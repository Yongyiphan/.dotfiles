local M = {
	{
		"p00f/clangd_extensions.nvim",
		after = "nvim-lspconfig",
		config = function()
			local cfg = _G.call and _G.call(_G.rprofile .. ".lsp.settings.c_cpp") or nil
			local ok, ext = pcall(require, "clangd_extensions")
			if not ok then return end
			ext.setup({
				server     = cfg and cfg.opts or {},
				extensions = cfg and cfg.extensions or {},
			})
		end,
	},
}

return M
