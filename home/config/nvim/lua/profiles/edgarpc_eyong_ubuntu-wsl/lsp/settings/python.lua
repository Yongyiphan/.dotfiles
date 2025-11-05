---@type LanguageProfile
local M = vim.deepcopy(require("profiles.template.lsp.settings_template"))

-- identity / scope
M.meta.lang = "python"
M.files.filetypes = { "python" }

-- LSP: pyright
M.lsp.pyright = {
  enabled = true,
  cmd = { "pyright-langserver", "--stdio" },
  root_dir_markers = { "pyproject.toml", "setup.cfg", "setup.py", ".pylintrc", ".git" },
  filetypes = { "python" },
  settings = {
    python = {
      venvPath = ".",          -- project root
      venv = ".venv",          -- use .venv in project
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        extraPaths = { "." },  -- make root importable
      },
    },
  },
}

-- use null-ls path
M.use_none_ls = true
M.none_ls = {
  formatting = { "black", "isort" },
  diagnostics = { "pylint", "mypy" },
  code_actions = { "refactoring" },
}

-- format-on-save
M.format_on_save.enable = true
M.format_on_save.vars = { line_length = 100 }

-- Provide all null-ls sources with correct config
M.hooks.none_ls_sources = function(builtins)
  return {
    -- Formatting
    builtins.formatting.black.with({
      prefer_local = ".venv/bin",
      extra_args = { "--line-length", tostring(M.format_on_save.vars.line_length or 100) },
    }),
    builtins.formatting.isort.with({
      prefer_local = ".venv/bin",
      extra_args = { "--profile", "black", "--line-length", tostring(M.format_on_save.vars.line_length or 100) },
    }),

    -- Diagnostics
    builtins.diagnostics.pylint.with({
      prefer_local = ".venv/bin",
      -- critical: make pylint see project root on sys.path
      extra_args = { "--init-hook", "import sys, os; sys.path.append(os.getcwd())" },
    }),
    builtins.diagnostics.mypy.with({
      prefer_local = ".venv/bin",
      -- helps mypy use project venv interpreter
      extra_args = { "--python-executable", ".venv/bin/python" },
    }),

    -- Code actions
    builtins.code_actions.refactoring,
  }
end

-- keep default none-ls on_attach (your pipeline wraps its own anyway)
M.hooks.none_ls_on_attach = function(_, _) return true end

-- (Optional) disable external installer since we’re using local venv/tools
M.installer.enabled = false

return M

