local M = {}

function M.setup()
  local servers_mod = _G.call("ega.custom.lsp.servers")
  if not servers_mod then return end
  local settings = servers_mod.get_settings()
  local servers = {}
  for _, cfg in ipairs(settings) do
    servers[#servers+1] = cfg.name
  end
  local mlsp = _G.call("mason-lspconfig")
  if not mlsp then return end
  mlsp.setup({ ensure_installed = servers })
end

return M