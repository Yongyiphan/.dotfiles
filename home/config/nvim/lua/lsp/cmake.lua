return {
	meta = {
		name = "cmake",
		filetypes = { "cmake" },
	},
	lsp = {
		cmake = {
			enabled = true,
			cmd = { "cmake-language-server" },
			root_dir_markers = { "CMakeLists.txt", ".git" },
			settings = {
				cmake = {
					buildDirectory = "build",
				},
			},
		},
	},
	install = {
		mason = { "cmake", "cmakelang" },
		system = {},
		project_local = {},
	},
	editor = {
		format_on_save = { enabled = true },
		none_ls_sources = function(builtins)
			return {
				builtins.formatting.cmake_format.with({
					extra_args = { "--line-width", "100" },
				}),
				builtins.diagnostics.cmake_lint.with({
					extra_args = { "--config=-" },
				}),
			}
		end,
	},
	plugins = {},
}
