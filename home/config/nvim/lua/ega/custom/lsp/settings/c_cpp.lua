local M = {}

M.name = "clangd"
M.opts = {
	cmd = {
		"clangd",
		"--all-scopes-completion",
		"--background-index",
		"--clang-tidy",
		"--completion-parse=always",
		"--completion-style=bundled",
		"--enable-config", -- clangd 11+ supports reading from .clangd configuration file
		"--function-arg-placeholders",
		"--header-insertion=iwyu",
	},
	filetypes = { "c", "cpp", "objc", "objcpp", "h", "hpp", "tpp", "inl" },
}

M.root_patterns = {
	".clangd",
	"compile_commands.json",
	"compile_flags.txt",
}
M.tools = { "clangd", "clang-format", "cpplint" }
M.null_ls = {
	formatting  = { "clang_format" },
	diagnostics = { "cpplint" },
}

M.clangd_extensions = {
	inlay_hints = {
		-- inline_parameter_names = true,
	},
}

return M

