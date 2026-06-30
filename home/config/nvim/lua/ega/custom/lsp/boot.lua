-- lua/ega/custom/lsp/boot.lua
if vim.g._lsp_boot_done then return end
vim.g._lsp_boot_done = true

-- Handlers (keymaps, LspAttach, etc.)
pcall(function()
  local h = require("ega.custom.lsp.handlers")
  if type(h.setup) == "function" then h.setup() end
end)

-- Discover + install + start LSP + wire formatting per LanguageProfile
local ok_pipe, pipeline = pcall(require, "ega.custom.lsp.pipeline")
if ok_pipe and type(pipeline.setup_all) == "function" then
	print("Setting up LSP")
  pipeline.setup_all()
end

-- Register LspRestart command
vim.api.nvim_create_user_command("LspRestart", function(opts)
  local restart = require("ega.custom.lsp.restart")
  if opts.args ~= "" then
    restart.restart_attached(opts.args)
  else
    restart.restart_by_name()
  end
end, {
  nargs = "?",
  complete = function()
    local names, seen = {}, {}
    for _, c in ipairs(vim.lsp.get_clients()) do
      if c.name and not seen[c.name] then
        seen[c.name] = true
        table.insert(names, c.name)
      end
    end
    table.sort(names)
    return names
  end,
})
