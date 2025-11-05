-- lua/ega/profiles/<your_profile>/lsp/settings/cmake.lua
---@type LanguageProfile
local M = vim.deepcopy(require("profiles.template.lsp.settings_template"))

-- identity / scope
M.meta.lang = "cmake"
M.files.filetypes = { "cmake" }

-- LSP: cmake-language-server
M.lsp.cmake = {
  enabled = true,
  cmd = { "cmake-language-server" },
  root_dir_markers = { "CMakeLists.txt", ".git" },
  filetypes = { "cmake" },
  settings = {
    cmake = {
      buildDirectory = "build", -- adjust if you use a different out-of-source dir
    },
  },
}

-- use none-ls
M.use_none_ls = true
M.none_ls = {
  formatting  = { "cmake_format" },
  diagnostics = { "cmake_lint" },
  code_actions = {},
}

-- format-on-save
M.format_on_save.enable = true
M.format_on_save.vars = { line_length = 100 }

-- none-ls source wiring
M.hooks.none_ls_sources = function(builtins)
  return {
    -- Formatting (cmake-format)
    builtins.formatting.cmake_format.with({
      -- cmake-format reads .cmake-format.yaml if present; nudge width otherwise
      extra_args = { "--line-width", tostring(M.format_on_save.vars.line_length or 100) },
    }),

    -- Diagnostics (cmakelint)
    builtins.diagnostics.cmake_lint.with({
      -- Example: lower noise; tweak to taste
      extra_args = { "--config=-" }, -- use defaults; respects .cmakelintrc if present
    }),
  }
end

-- keep default none-ls on_attach
M.hooks.none_ls_on_attach = function(_, _) return true end

-- We use system tools; skip external installer
M.installer.enabled = false

return M

