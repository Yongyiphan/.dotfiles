local rt = vim.split(package.path or "", ";")
if type(rt) == "table" then
	table.insert(rt, "lua/?.lua")
	table.insert(rt, "lua/?/init.lua")
else
	rt = { "lua/?.lua", "lua/?/init.lua" }
end
return {
	meta = {
		name = "lua_ls",
		filetypes = { "lua" },
	},
	lsp = {
		lua_ls = {
			enabled = true,
			cmd = { "lua-language-server" },
			root_dir_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
			settings = {
				Lua = {
					runtime = { version = "LuaJIT", path = rt },
					diagnostics = { globals = { "vim" } },
					workspace = {
						library = vim.api.nvim_get_runtime_file("lua", true),
						checkThirdParty = false,
					},
					telemetry = { enable = false },
					hint = { enable = true },
				},
			},
		},
	},
	install = {
		mason = { "lua_ls", "stylua" },
		system = {},
		project_local = {},
	},
	editor = {
		format_on_save = { enabled = true },
		none_ls_sources = function(builtins)
			return {
				builtins.formatting.stylua.with({
					condition = function()
						return vim.fn.executable("stylua") == 1
					end,
				}),
			}
		end,
	},
	plugins = {},
}
