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

