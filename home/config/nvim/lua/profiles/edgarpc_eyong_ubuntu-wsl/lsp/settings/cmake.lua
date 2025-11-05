local M = {}

M.name = "cmake"
M.opts = { filetypes = { "cmake" } }
M.tools = { "cmake-language-server" }
M.null_ls = { formatting = {}, diagnostics = {} }

return M