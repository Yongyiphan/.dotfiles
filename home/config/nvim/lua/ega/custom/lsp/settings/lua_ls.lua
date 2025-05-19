local M = {}
local rt = vim.split(package.path, ";")
if rt then
  table.insert(rt, "lua/?.lua")
  table.insert(rt, "lua/?/init.lua")
end

M.name = "lua_ls"
M.opts = {
  settings = { Lua = {
    runtime   = { version = "LuaJIT", path = rt },
    diagnostics= { globals = { "vim" } },
    workspace = { library = vim.api.nvim_get_runtime_file("lua", true), checkThirdParty = false },
    telemetry = { enable = false },
  }},
}

M.tools = { "lua-language-server", "stylua" }
M.null_ls = { formatting = { "stylua" }, diagnostics = {} }

return M