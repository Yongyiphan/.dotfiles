local mason, mason_lsp, lspconfig = _G.call("mason"), _G.call("mason-lspconfig"), _G.call("lspconfig")
if not mason or not mason_lsp or not lspconfig then
	return
end

local M = {
	ensure_installed = {
	
		"clangd",
		"cmake",
		"lua_ls",
		"pyright",
	},
	capabilities = {
		["cmp_nvim"] = require("cmp_nvim_lsp").default_capabilities(),
	},
}

M.setup = function(capabilities)
	vim.filetype.add({
		extension = {
			tpp = "cpp",
			--vert = "cpp",
			--frag = "cpp",
		},
		pattern = {
			[".*.tpp"] = "cpp",
			--		[".*.vert"] = "cpp",
			--		[".*.frag"] = "cpp",
		},
	})
	mason.setup()
	mason_lsp.setup({
		ensure_installed = M.ensure_installed,
	})
	require("cmp").setup({
		sources = {
			{ name = "nvim_lsp" },
		},
	})
	
	capabilities = capabilities or M.capabilities["cmp_nvim"]
	
	lspconfig.lua_ls.setup({
		settings = require("ega.custom.lsp.settings.lua_ls"),
		capabilities = capabilities,
	})
	
	lspconfig.pyright.setup(require("ega.custom.lsp.settings.python").setup)
	
	-- require("clangd_extensions").setup({
	-- 	server = require("ega.custom.lsp.settings.clangd"),
	-- })
	lspconfig.clangd.setup(require("ega.custom.lsp.settings.clangd"))
	--lspconfig.glslls.setup()
	--TODO(REPLACE)
	require("ega.custom.lsp.null_ls")
	-- require("ega.custom.lsp.formatter")
	-- require("ega.custom.lsp.linter")
end

--Outside of M.setup()
M.setup()

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
		
		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local opts = { buffer = ev.buf }
		vim.keymap.set("n", "<leader>iD", vim.lsp.buf.declaration, _G.KeyOpts("Declaration", opts))
		vim.keymap.set("n", "<leader>id", vim.lsp.buf.definition, _G.KeyOpts("Definition", opts))
		vim.keymap.set("n", "<leader>ih", vim.lsp.buf.hover, _G.KeyOpts("Hover", opts))
		vim.keymap.set("n", "<leader>iI", vim.lsp.buf.implementation, _G.KeyOpts("Implementation", opts))
		vim.keymap.set("n", "<leader>ir", vim.lsp.buf.references, _G.KeyOpts("References", opts))
		vim.keymap.set("n", "<leader>if", vim.lsp.buf.format, _G.KeyOpts("Format", opts))
	end,
})

return M
