local M = {}

-- cmp capabilities (optional)
local cmp = _G.call("cmp_nvim_lsp")
local caps = (cmp and cmp.default_capabilities()) or vim.lsp.protocol.make_client_capabilities()

-- Collect settings from built-ins and profile
local customlsp = require(_G.rprofile .. ".lsp")  -- your profile index (names list)
local settings = {}
do
  local names = { "lua_ls" } -- any built-ins you ship
  for _, name in ipairs(names) do
    local mod = _G.call("ega.custom.lsp.settings." .. name)
    if mod then table.insert(settings, mod) end
  end
  for _, name in ipairs(customlsp.names) do
    local mod = _G.call(_G.rprofile .. ".lsp.settings." .. name)
    if mod then table.insert(settings, mod) end
  end
end

function M.get_settings() return settings end

local function start_server_by_name(name, opts)
  if vim.lsp.get_clients({ name = name })[1] then return end
  local cfg = vim.lsp.config(vim.tbl_deep_extend("force", {
    name = name,
    capabilities = caps,
  }, opts or {}))
  vim.lsp.start(cfg)
end

function M.setup()
  for _, cfg in ipairs(settings) do
    -- expecting each cfg like: { name = "pyright", opts = {...}, root_patterns = {...} }
    if cfg and cfg.name then
      local root = nil
      if cfg.root_patterns then root = vim.fs.root(0, cfg.root_patterns) end
      local opts = vim.tbl_deep_extend("force", {}, cfg.opts or {})
      if root then opts.root_dir = root end
      start_server_by_name(cfg.name, opts)
    end
  end
end

return M

