return {
	meta = {
		name = "markdown",
		filetypes = { "markdown", "md", "mdx" },
	},
	lsp = {
		marksman = {
			enabled = true,
			cmd = { "marksman", "server" },
			root_dir_markers = { ".git", ".marksman.toml", ".marksman.yml", ".marksman.yaml" },
		},
	},
	install = {
		mason = { "marksman", "prettier" },
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
			enabled = false,
		},
		none_ls_sources = function(builtins)
			local formatting = builtins and builtins.formatting or nil
			if not formatting or not formatting.prettier then
				return {}
			end
			return {
				formatting.prettier.with({
					prefer_local = "node_modules/.bin",
					extra_args = {
						"--print-width",
						"100",
						"--prose-wrap",
						"always",
					},
				}),
			}
		end,
	},
	plugins = {},
}
