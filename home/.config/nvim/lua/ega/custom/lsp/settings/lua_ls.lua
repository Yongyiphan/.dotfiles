local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

local settings = {
	Lua = {
		runtime = {
			version = "LuaJIT",
			path = runtime_path,
			--version = _G.lua_version,
			--path = {
      --  '?.lua',
      --  '?/init.lua',
      --  vim.fn.expand'~/.luarocks/share/lua/' .. _G.lua_version .. '/?.lua',
      --  vim.fn.expand'~/.luarocks/share/lua/' .. _G.lua_version ..'/?/init.lua',
      --  '/usr/share/' .. _G.lua_version .. '/?.lua',
      --  '/usr/share/lua/' .. _G.lua_version .. '/?/init.lua'
      --}
		},
		diagnostics = {
			globals = {'vim'},
		},
		workspace = {
			library = vim.api.nvim_get_runtime_file("", true),
			checkThirdParty = false,
		},
		telemetry = {
			enable = false,
		}
	}
}
return settings
