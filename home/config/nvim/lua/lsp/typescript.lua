---@type LanguageProfile
local FullProfile = vim.deepcopy(require("profiles.template.lsp.settings_template"))

-- Language-specific plugins (Lazy specs)
FullProfile.plugins = {
  {
    "yioneko/nvim-vtsls",
    -- opts = { } -- if you ever need to configure it
  },
}

local S = FullProfile.settings

-- identity / scope
S.meta.lang = "typescript"
S.files.filetypes = {
  "typescript",
  "typescriptreact",
  "javascript",
  "javascriptreact",
}

-- LSP: vtsls (modern TS/JS/JSX/TSX server)
S.lsp.vtsls = {
  enabled = true,
  cmd = { "vtsls", "--stdio" },
  root_dir_markers = {
    "tsconfig.json",
    "jsconfig.json",
    "package.json",
    "app.json",
    ".git",
  },
  settings = {
    typescript = {
      format = {
        insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
      },
    },
    javascript = {
      format = {
        insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
      },
    },
  },
}

-- Use none-ls ONLY for Prettier formatting (no eslint)
S.use_none_ls = true
S.none_ls = {
  formatting = { "prettier" },
  diagnostics = {},   -- important: nothing here
  code_actions = {},
}

-- Format-on-save for app code
S.format_on_save.enable = true
S.format_on_save.vars = {
  print_width = 100,
}

-- null-ls sources for TS/JS: Prettier only
S.hooks.none_ls_sources = function(builtins)
  local sources = {}

  -- Defensive guard: builtins or formatting may be nil
  local fmt = builtins and builtins.formatting or nil
  if fmt and fmt.prettier then
    table.insert(sources, fmt.prettier.with({
      extra_args = {
        "--print-width",
        tostring(S.format_on_save.vars.print_width or 100),
      },
    }))
  end

  return sources
end

S.hooks.none_ls_on_attach = function()
  return true
end

-- Optional: installer helpers (used by language_installer.lua)
S.installer.enabled = true
S.installer.steps = {
  {
    tool = "vtsls",
    check = "vtsls",
    cmd = function(u)
      u.exec({ "npm", "install", "-g", "vtsls", "@vtsls/language-server" })
    end,
  },
  {
    tool = "prettier",
    check = "prettier",
    cmd = function(u)
      u.exec({ "npm", "install", "-g", "prettier" })
    end,
  },
}

return FullProfile

