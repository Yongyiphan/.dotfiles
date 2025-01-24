local M = {}
vim.diagnostic.config({
	virtual_text = false,
	signs = true,
	float = {
		source = "always",
		border = "single",
		format = function(diagnostic)
			return string.format("%s (%s) [%s]", diagnostic.message, diagnostic.source, diagnostic.code)
		end,
	},
})

--local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
local signs = { Error = "E ", Warn = "W ", Hint = "H ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

function M.close_diag_window(scope)
	-- If we find a floating window, close it.
	local found_float = false
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(win).relative ~= "" then
			vim.api.nvim_win_close(win, true)
			found_float = true
		end
	end
	if found_float then
		return
	end
	vim.diagnostic.open_float(nil, { focus = true, scope = scope })
end

function M.close_diag_at_line()
	M.close_diag_window("l")
end

function M.close_diag_at_cursor()
	M.close_diag_window("c")
end

function PrintDiagnostics(opts, bufnr, line_nr, client_id)
	bufnr = bufnr or 0
	line_nr = line_nr or (vim.api.nvim_win_get_cursor(0)[1] - 1)
	opts = opts or { ["lnum"] = line_nr }

	local line_diagnostics = vim.diagnostic.get(bufnr, opts)
	if vim.tbl_isempty(line_diagnostics) then
		return
	end

	local diagnostic_message = ""
	for i, diagnostic in ipairs(line_diagnostics) do
		diagnostic_message = diagnostic_message .. string.format("%d: %s", i, diagnostic.message or "")
		print(diagnostic_message)
		if i ~= #line_diagnostics then
			diagnostic_message = diagnostic_message .. "\n"
		end
	end
	vim.api.nvim_echo({ { diagnostic_message, "Normal" } }, false, {})
end

--vim.cmd([[ autocmd! CursorHold * lua PrintDiagnostics() ]])
return M
