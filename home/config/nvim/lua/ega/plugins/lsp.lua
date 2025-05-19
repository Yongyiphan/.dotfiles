local Languages = _G.call("ega.plugins.lspLang")
local P = {
  -- Mason core installer
  {
    "williamboman/mason.nvim",
    cmd   = { "Mason", "MasonInstall", "MasonUpdate" },
    build = ":MasonUpdate",
    config = function()
      local mason_mod = _G.call("ega.custom.lsp.mason")
      if not mason_mod then return end
      mason_mod.setup()
    end,
  },
  -- Mason tool installer (servers + CLI tools)
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    after = "mason.nvim",
    config = function()
      local mason_mod = _G.call("ega.custom.lsp.mason")
      if not mason_mod then return end
      mason_mod.setup_installer()
    end,
  },
  -- Bridge Mason → LSPConfig
  {
    "williamboman/mason-lspconfig.nvim",
    after = { "mason.nvim", "mason-tool-installer.nvim" },
    config = function()
      local mlsp = _G.call("ega.custom.lsp.mason_lsp")
      if not mlsp then return end
      mlsp.setup()
    end,
  },
  -- Core LSP client
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local init = _G.call("ega.custom.lsp")
      if not init then return end
      init.setup()
    end,
  },
  -- clangd extensions (C/C++)
  {
    "p00f/clangd_extensions.nvim",
    after  = "nvim-lspconfig",
    config = function()
      local cfg = _G.call("ega.custom.lsp.settings.c_cpp")
      if not cfg then return end
      local ext = _G.call("clangd_extensions")
      if not ext then return end
      ext.setup({
        server     = cfg.opts,
        extensions = cfg.extensions or {},
      })
    end,
  },
  -- Completion + snippets
  {
    "hrsh7th/nvim-cmp",
    event        = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "L3MON4D3/LuaSnip",
      "windwp/nvim-autopairs",
    },
    config = function()
      local cmp_mod = _G.call("ega.custom.autocmp")
      if not cmp_mod then return end
      cmp_mod.setup()
    end,
  },
  -- none-ls for formatting & diagnostics
  {
    "nvimtools/none-ls.nvim",
    after        = "mason-lspconfig.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local ns = _G.call("ega.custom.lsp.null_ls")
      if not ns then return end
      ns.setup()
    end,
  },
  Languages
}

return P
