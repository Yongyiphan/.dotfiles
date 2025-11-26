--@type LanguageProfile
local FullProfile = {}
local plugins = {}
local M = {}
M.meta = {
	lang = "template",
	version = 1,
}

M.tools = {}

M.files = {
	filetypes = { "template" },
	patterns = {},
}

M.use_none_ls = true
M.none_ls = {
	formatting = {},
	diagnostics = {},
	code_actions = {},
	extra_requires = {},
}

M.format_on_save = {
	enable = true,
	order = {},
	line_length = 100
}

M.lsp = {}

M.installer = {
	enabled = false,
	steps = {
		-- Example function step:
		-- { tool="pyright", check="pyright-langserver", cmd=function(u) u.exec({ "npm", "i", "-g", "pyright" }) end },
		-- Example argv step:
		-- { tool="black", check="black", run={ "pipx", "install", "black" } },
	},
}

M.hooks = {
	--- Build and return an array of none-ls sources.
	---@param builtins table  -- null_ls.builtins
	---@return table          -- list of sources
	none_ls_sources = nil, -- function(builtins) return { builtins.formatting.black, ... } end
	
	--- Called by none-ls on_attach; return false to skip adding the default BufWritePre.
	---@param client vim.lsp.Client
	---@param bufnr integer
	---@return boolean|nil    -- return false to disable default on_attach formatter
	none_ls_on_attach = nil, -- function(client, bufnr) end
	
	--- Buffer-local external formatter. If provided, pipeline won’t run the default CLI chain.
	---@param opts {filename:string, bufnr:integer, line_length:integer}
	external_cli = nil, -- function(opts) end
}

FullProfile.plugins = plugins
FullProfile.settings = M

return FullProfile
