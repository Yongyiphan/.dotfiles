local M = {}
function M.setup()
  local group = vim.api.nvim_create_augroup("LspAttach", {})
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
      local km = vim.keymap.set
      local opts = { buffer = bufnr }

      -- Standard LSP mappings
      km("n", "gd", vim.lsp.buf.definition, opts)
      km("n", "K", vim.lsp.buf.hover, opts)
      km("n", "<leader>rn", vim.lsp.buf.rename, opts)
      km("n", "<leader>ca", vim.lsp.buf.code_action, opts)

      -- Additional <leader>i mappings
      km("n", "<leader>iD", vim.lsp.buf.declaration, _G.KeyOpts("Declaration", opts))
      km("n", "<leader>id", vim.lsp.buf.definition, _G.KeyOpts("Definition", opts))
      km("n", "<leader>ih", vim.lsp.buf.hover, _G.KeyOpts("Hover", opts))
      km("n", "<leader>iI", vim.lsp.buf.implementation, _G.KeyOpts("Implementation", opts))
      km("n", "<leader>ir", vim.lsp.buf.references, _G.KeyOpts("References", opts))
      km("n", "<leader>if", vim.lsp.buf.format, _G.KeyOpts("Format", opts))
    end,
  })
end
return M