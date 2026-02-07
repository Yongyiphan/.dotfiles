---@type LanguageProfile
local FullProfile = vim.deepcopy(require("profiles.template.lsp.settings_template"))

-- Language-specific plugins (Lazy specs)
FullProfile.plugins = {
  -- Markdown LSP
  { "artempyanykh/marksman" },

  -- Optional live preview (safe to remove if you do not want it)
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown", "md", "mdx" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
}

local S = FullProfile.settings

-- identity / scope
S.meta.lang = "markdown"
S.files.filetypes = { "markdown", "md", "mdx" }

-- LSP: marksman
S.lsp.marksman = {
  enabled = true,
  cmd = { "marksman", "server" },
  root_dir_markers = { ".git", ".marksman.toml", ".marksman.yml", ".marksman.yaml" },
}

-- Use none-ls for optional Prettier formatting
S.use_none_ls = true
S.none_ls = {
  formatting = { "prettier" },
  diagnostics = {},
  code_actions = {},
}

-- Do not auto-format Markdown on save by default
S.format_on_save.enable = false
S.format_on_save.vars = {
  print_width = 100,
}

-- null-ls sources for Markdown: Prettier only, guarded
S.hooks.none_ls_sources = function(builtins)
  local sources = {}

  local fmt = builtins and builtins.formatting or nil
  if fmt and fmt.prettier then
    table.insert(sources, fmt.prettier.with({
      extra_args = {
        "--print-width",
        tostring(S.format_on_save.vars.print_width or 100),
        "--prose-wrap",
        "always",
      },
    }))
  end

  return sources
end

S.hooks.none_ls_on_attach = function()
  return true
end

-- No installer steps; assume tools handled elsewhere (Mason, system, etc.)
S.installer.enabled = false

return FullProfile

