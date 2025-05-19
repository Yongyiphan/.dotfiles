local M = {}

function M.setup()
  local mason = _G.call("mason")
  if not mason then return end
  mason.setup()
end

function M.setup_installer()
  local servers_mod = _G.call("ega.custom.lsp.servers")
  if not servers_mod then return end
  local settings = servers_mod.get_settings()
  local tools = {}
  for _, cfg in ipairs(settings) do
    for _, t in ipairs(cfg.tools or {}) do
      tools[#tools+1] = t
    end
  end
  -- dedupe
  local seen, list = {}, {}
  for _, t in ipairs(tools) do
    if not seen[t] then seen[t] = true; list[#list+1] = t end
  end
  local installer = _G.call("mason-tool-installer")
  if not installer then return end
  installer.setup({
    ensure_installed = list,
    auto_update      = true,
    run_on_start     = true,
  })
end

return M