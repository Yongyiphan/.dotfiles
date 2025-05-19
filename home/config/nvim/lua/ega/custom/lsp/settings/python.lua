local M = {}

M.name = "pyright"
M.opts = { settings = { python = { analysis = { typeCheckingMode = "basic", autoSearchPaths = true } } } }

M.tools = { "pyright", "black", "ruff", "mypy" }
M.null_ls = { formatting = { "black" }, diagnostics = { "flake8", "ruff" } }

return M

