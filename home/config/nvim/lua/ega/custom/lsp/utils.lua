local M = {}

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
	
	-- (c) Re-trigger your FileType autostart (your pipeline hooks onto FileType)
	-- This runs all FileType autocmds again for this buffer, which will call start_lsp()
	vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
	
	-- (d) Nudge the buffer to ensure reattach & diagnostics refresh
	vim.defer_fn(function() pcall(vim.cmd, "edit") end, 50)
	
	vim.notify(
		string.format("LSP restarted for buffer%s", name and (" (" .. name .. ")") or ""),
		vim.log.levels.INFO
	)
end

-- Use Telescope to pick an LSP name to restart
function M.restart_by_name()
	local ok, telescope = pcall(require, 'telescope')
	if not ok then
		vim.notify('Telescope not available', vim.log.levels.ERROR)
		return
	end
	local buf = vim.api.nvim_get_current_buf()
	local names, seen = {}, {}
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
		if c.name and not seen[c.name] then
			seen[c.name] = true
			table.insert(names, c.name)
		end
	end
	table.sort(names)
	if #names == 0 then
		vim.notify('No LSP clients attached to this buffer', vim.log.levels.WARN)
		return
	end
	telescope.pickers = telescope.pickers or require('telescope.pickers')
	telescope.finders = telescope.finders or require('telescope.finders')
	telescope.sorters = telescope.sorters or require('telescope.sorters')
	local pickers, finders, sorters = telescope.pickers, telescope.finders, telescope.sorters
	pickers.new({}, {
		prompt_title = 'Select LSP to Restart',
		finder = finders.new_table({ results = names }),
		sorter = sorters.get_generic_fuzzy_sorter(),
		attach_mappings = function(_, map)
			local actions = require('telescope.actions')
			local action_state = require('telescope.actions.state')
			map('i', '<CR>', function(prompt_bufnr)
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection and selection[1] then
					M.restart_attached(selection[1])
				end
			end)
			map('n', '<CR>', function(prompt_bufnr)
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection and selection[1] then
					M.restart_attached(selection[1])
				end
			end)
			return true
		end,
	}):find()
end

return M
