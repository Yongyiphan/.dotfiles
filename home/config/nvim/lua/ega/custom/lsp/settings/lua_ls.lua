---@type LanguageProfile
local M = vim.deepcopy(require("profiles.template.lsp.settings_template"))

-- identity / scope
M.meta.lang = "lua"
M.files.filetypes = { "lua" }

-- runtime path (preserve your old behavior)
local rt = vim.split(package.path or "", ";")
if type(rt) == "table" then
  table.insert(rt, "lua/?.lua")
  table.insert(rt, "lua/?/init.lua")
else
  rt = { "lua/?.lua", "lua/?/init.lua" }
end

-- LSP (Neovim 0.11 API consumer)
M.lsp.lua_ls = {
  enabled = true,
  cmd = { "lua-language-server" },
  root_dir_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT", path = rt },
      diagnostics = { globals = { "vim" } },
      workspace = {
        -- keep your previous library enrichment
        library = vim.api.nvim_get_runtime_file("lua", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
      hint = { enable = true },
    },
  },
}

-- Use none-ls for formatting/diagnostics (strict: only if we declare sources)
M.use_none_ls = true
M.format_on_save.enable = true
M.none_ls = {
  formatting = {"stylua"},
}


-- STRICT: profile declares all none-ls sources (no defaults)
M.hooks.none_ls_sources = function(b)
  return {
    b.formatting.stylua,
    -- Optional diagnostics (enable only if you actually use them):
    -- b.diagnostics.selene.with({
    --   condition = function(utils)
    --     return utils.root_has_file({ "selene.toml", ".selene.toml", "selene.yml" })
    --   end,
    -- }),
    -- b.diagnostics.luacheck.with({
    --   condition = function(utils)
    --     return utils.executable("luacheck") and utils.root_has_file({ ".luacheckrc", ".luacheckrc.lua" })
    --   end,
    -- }),
  }
end

-- Keep the pipeline’s default BufWritePre formatter from none-ls
M.hooks.none_ls_on_attach = function() return true end

-- Optional fallback installers (pipeline will prefer Mason/MTI if present)
M.installer.enabled = true
M.installer.steps = {
  { tool = "stylua", check = "stylua",
    cmd = function(u) u.exec({ "cargo", "install", "stylua" }) end },
  -- { tool = "selene", check = "selene",
  --   cmd = function(u) u.exec({ "cargo", "install", "selene" }) end },
  -- { tool = "luacheck", check = "luacheck",
  --   cmd = function(u) u.exec({ "luarocks", "install", "luacheck" }) end },
  -- lua-language-server: prefer Mason; OS-specific manual install is messy.
}

return M

