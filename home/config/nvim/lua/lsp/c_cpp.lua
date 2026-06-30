return {
	meta = {
		name = "c_cpp",
		filetypes = { "c", "cpp", "objc", "objcpp", "h", "hpp", "tpp", "inl" },
	},
	lsp = {
		clangd = {
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
			settings = {},
		},
	},
	install = {
		mason = { "clangd", "clang-format", "cpplint" },
		system = {
			apt = { "cppcheck" },
			dnf = { "cppcheck" },
			pacman = { "cppcheck" },
			brew = { "cppcheck" },
		},
		project_local = {},
	},
	editor = {
		format_on_save = { enabled = true },
		none_ls_sources = function(builtins)
			return {
				builtins.formatting.clang_format.with({
					extra_args = { "--style", "{ BasedOnStyle: LLVM, ColumnLimit: 100 }" },
				}),
				builtins.diagnostics.cpplint.with({
					extra_args = { "--linelength=100" },
				}),
				builtins.diagnostics.cppcheck.with({
					extra_args = { "--enable=warning,style,performance,portability" },
				}),
			}
		end,
	},
	plugins = {},
}
