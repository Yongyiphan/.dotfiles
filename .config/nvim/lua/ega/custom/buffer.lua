local close_buffer = _G.call("close_buffers")
local bufferline = _G.call("bufferline")
if not close_buffer then
	return
end
if not bufferline then
	return
end

vim.opt.termguicolors = true
bufferline.setup({
	options = {
		themable = true,
		indicator = {
			style = "underline",
		},
		diagnostics = "nvim_lsp",
		diagnostics_indicator = function(count, level)
			local icon = level:match("error") and " " or ""
			return icon .. " " .. count
		end,
	},
})

close_buffer.setup({
	preserve_window_layout = { "this" },
	next_buffer_cmd = function(windows)
		bufferline.cycle(1)
		local bufnr = vim.api.nvim_get_current_buf()
		for _, window in ipairs(windows) do
			vim.api.nvim_win_set_buf(window, bufnr)
		end
	end,
})
