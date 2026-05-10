return {
	meta = {
		name = "typescript",
		filetypes = {
			"typescript",
			"typescriptreact",
			"javascript",
			"javascriptreact",
		},
	},
	lsp = {
		vtsls = {
			enabled = true,
			cmd = { "vtsls", "--stdio" },
			root_dir_markers = {
				"tsconfig.json",
				"jsconfig.json",
				"package.json",
				"app.json",
				".git",
			},
			settings = {
				typescript = {
					format = {
						insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
					},
				},
				javascript = {
					format = {
						insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
					},
				},
			},
		},
	},
	install = {
		mason = { "vtsls", "prettier" },
		system = {
			apt = { "nodejs", "npm" },
			dnf = { "nodejs", "npm" },
			pacman = { "nodejs", "npm" },
			brew = { "node" },
		},
		project_local = {
			tools = { "prettier" },
			note = "node_modules/.bin tools are preferred when available.",
		},
	},
	editor = {
		format_on_save = {
			enabled = true,
		},
		none_ls_sources = function(builtins)
			local formatting = builtins and builtins.formatting or nil
			if not formatting or not formatting.prettier then
				return {}
			end
			return {
				formatting.prettier.with({
					prefer_local = "node_modules/.bin",
					extra_args = { "--print-width", "100" },
				}),
			}
		end,
	},
	plugins = {},
}
