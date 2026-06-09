local M = {}

function M.notify_file_operation(changes)
	if type(changes) ~= "table" or #changes == 0 then
		return
	end

	vim.defer_fn(function()
		pcall(vim.cmd, "checktime")

		local ok, lsp_profile = pcall(require, "ega.custom.lsp")
		if not ok or type(lsp_profile.get_active_definitions) ~= "function" then
			return
		end

		for _, def in ipairs(lsp_profile.get_active_definitions()) do
			local handler = ((def.editor or {}).file_operations or {}).on_change
			if type(handler) == "function" then
				pcall(handler, {
					changes = changes,
				})
			end
		end
	end, 1000)
end

-- Stop LSP clients attached to the current buffer and reattach them.
-- Optional: pass a client name (e.g., "pyright") to restart only that one.
function M.restart_attached(name)
	local buf = vim.api.nvim_get_current_buf()
	
	-- (a) Clear buffer-local format-on-save hook created by pipeline (optional safety)
	pcall(vim.api.nvim_clear_autocmds, { group = "EgaFormatOnSaveLocal", buffer = buf })
	if vim.b[buf] then vim.b[buf].ega_local_format = nil end
	
	-- (b) Stop clients on this buffer (filtered by name if provided)
	local stopped = 0
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
		if (not name) or (c.name == name) then
			pcall(vim.lsp.stop_client, c.id, true)
			stopped = stopped + 1
		end
	end
	
	-- (c) Re-trigger FileType after clients have had time to stop.
	vim.defer_fn(function()
		vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
		pcall(vim.cmd, "edit")
	end, 150)
	
	vim.notify(
		string.format("LSP restarted for buffer%s", name and (" (" .. name .. ")") or ""),
		vim.log.levels.INFO
	)
end

-- Convenience: pick a name from clients attached to the current buffer.
function M.restart_by_name()
	local buf = vim.api.nvim_get_current_buf()
	local names, seen = {}, {}
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
		if c.name and not seen[c.name] then
			seen[c.name] = true
			table.insert(names, c.name)
		end
	end
	table.sort(names)
	
	local prompt = "LSP name to restart"
	if #names > 0 then prompt = prompt .. " (attached: " .. table.concat(names, ", ") .. ")" end
	prompt = prompt .. ": "
	
	vim.ui.input({ prompt = prompt }, function(input)
		if not input or input == "" then
			vim.notify("No LSP name provided", vim.log.levels.WARN)
			return
		end
		M.restart_attached(input)
	end)
end

return M
