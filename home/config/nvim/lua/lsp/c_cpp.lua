-- lua/ega/profiles/<your_profile>/lsp/settings/c_cpp.lua
--
---@type LanguageProfile
local FullProfile = vim.deepcopy(require("profiles.template.lsp.settings_template"))

FullProfile.plugins = {
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

local M = FullProfile.settings
-- identity / scope
M.meta.lang = "c_cpp"
M.files.filetypes = { "c", "cpp", "objc", "objcpp", "h", "hpp", "tpp", "inl" }

-- LSP: clangd
M.lsp.clangd = {
	enabled = true,
	cmd = {
		"clangd",
		"--all-scopes-completion",
		"--background-index",
		"--clang-tidy",
		"--completion-parse=always",
		"--completion-style=bundled",
		"--enable-config",
		"--function-arg-placeholders",
		"--header-insertion=iwyu",
	},
	root_dir_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", ".git" },
	filetypes = M.files.filetypes,
	settings = {}, -- keep defaults (clangd mostly uses flags/compile_commands)
}

-- use none-ls
M.use_none_ls = true
M.none_ls = {
	formatting   = { "clang_format" },
	diagnostics  = { "cpplint", "cppcheck" },
	code_actions = {},
}

-- format-on-save
M.format_on_save.enable = true
M.format_on_save.vars = { line_length = 100 }

-- none-ls source wiring
M.hooks.none_ls_sources = function(builtins)
	return {
		-- Formatting: clang-format will read .clang-format if present
		builtins.formatting.clang_format.with({
			-- If no .clang-format, at least keep a sane width
			extra_args = { "--style", "{ BasedOnStyle: LLVM, ColumnLimit: " .. tostring(M.format_on_save.vars.line_length or 100) .. " }" },
		}),
		
		-- Diagnostics
		builtins.diagnostics.cpplint.with({
			extra_args = { "--linelength=" .. tostring(M.format_on_save.vars.line_length or 100) },
		}),
		builtins.diagnostics.cppcheck.with({
			extra_args = { "--enable=warning,style,performance,portability" },
		}),
	}
end

-- keep default none-ls on_attach
M.hooks.none_ls_on_attach = function(_, _) return true end

-- We use system tools; skip external installer
M.installer.enabled = false

return FullProfile
