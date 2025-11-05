local M = {}

function M.setup()
  -- Safely require each dependency
  local ok_cmp, cmp = pcall(require, "cmp")
  if not ok_cmp then return end

  local ok_snip, luasnip = pcall(require, "luasnip")
  if not ok_snip then return end

  local ok_ap, autopairs = pcall(require, "nvim-autopairs")
  if not ok_ap then return end

	vim.o.completeopt = "menu,menuone,noselect"

  -- Basic autopairs setup
  autopairs.setup({})
  require("luasnip.loaders.from_vscode").lazy_load()

  -- Helper to detect when to trigger completion
  local has_words_before = function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    if col == 0 then return false end
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
    return not line:sub(col, col):match("%s")
  end

	local types = require("cmp.types")

  -- Main nvim-cmp setup
  cmp.setup({
		completion = {
			autocomplete = {types.cmp.TriggerEvent.TextChanged},
		},
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    sources = {
			{ name = "nvim_lsp" },
			--{ name = "coplilot", group_index = 2 },
			{ name = "luasnip" },
      { name = "path", keyword_length = 0 },
      { name = "buffer", keyword_length = 0 },
      { name = "nvim_lsp_signature_help" },
    },
		experimental = {ghost_text = true},
    mapping = cmp.mapping.preset.insert({
      ["<CR>"]      = cmp.mapping.confirm({ select = true }),
      ["<C-Space>"] = cmp.mapping.complete(),

      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable and luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        elseif has_words_before() then
					cmp.complete()
        else
          fallback()
					-- cmp.complete()
        end
      end, { "i", "s" }),

      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable and luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
  })

  -- Integrate autopairs with completion
  local cmp_autopairs = require("nvim-autopairs.completion.cmp")
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end

return M
