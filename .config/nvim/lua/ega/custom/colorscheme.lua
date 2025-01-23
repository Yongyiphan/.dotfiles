local nightfox_s, nightfox = pcall(require, nightfox)
if not nightfox_s then
	return
end

nightfox.setup({
	options = {
		terminal_colors = true,
	}
})

-- vim.cmd [[highlight Comment guifg=#6A9955 ctermfg=green]]
local function set_comment_highlight()
	vim.cmd [[highlight Comment guifg=#6A9955 ctermfg=green]]
end

vim.api.nvim_create_augroup("LSPCommentColor", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "ColorScheme" }, {
	group = "LSPCommentColor",
	pattern = "*",
	callback = set_comment_highlight,
})
