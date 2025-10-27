local M = {}

-- Stop all LSP clients attached to the current buffer and re-run your setup chain.
function M.restart_attached()
	local bufnr = vim.api.nvim_get_current_buf()
	
	-- 1) Stop all clients attached to this buffer
	local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
	for _, c in ipairs(clients) do
		pcall(vim.lsp.stop_client, c.id, true)
	end
	
	-- 2) Re-run your setup modules
	local handlers = _G.call("ega.custom.lsp.handlers")
	if handlers and handlers.setup then pcall(handlers.setup) end
	
	local servers_mod = _G.call("ega.custom.lsp.servers")
	if servers_mod and servers_mod.setup then pcall(servers_mod.setup) end
	
	local nulls = _G.call("ega.custom.lsp.null_ls")
	if nulls and nulls.setup then pcall(nulls.setup) end
	
	-- 3) Nudge re-attachment for this buffer
	vim.defer_fn(function()
		pcall(vim.cmd, "edit")
	end, 100)
	
	vim.notify("LSP restarted for current buffer", vim.log.levels.INFO)
end

-- Prompt for a specific client name and restart only that client (via :LspRestart).
function M.restart_by_name()
	local bufnr = vim.api.nvim_get_current_buf()
	local names, seen = {}, {}
	
	for _, c in ipairs(vim.lsp.get_active_clients({ bufnr = bufnr })) do
		if c.name and not seen[c.name] then
			seen[c.name] = true
			table.insert(names, c.name)
		end
	end
	
	table.sort(names)
	
	local prompt = "LSP name to restart"
	if #names > 0 then
		prompt = prompt .. " (attached: " .. table.concat(names, ", ") .. ")"
	end
	prompt = prompt .. ": "
	
	vim.ui.input({ prompt = prompt }, function(input)
		if not input or input == "" then
			vim.notify("No LSP name provided", vim.log.levels.WARN)
			return
		end
		-- Try the command route (provided by nvim-lspconfig)
		local ok, err = pcall(vim.cmd, "LspRestart " .. input)
		if ok then
			vim.notify("Requested LspRestart for: " .. input)
			return
		end
		
		-- Fallback: manually stop clients matching this name and re-run setup
		local stopped = 0
		for _, c in ipairs(vim.lsp.get_active_clients()) do
			if c.name == input then
				pcall(vim.lsp.stop_client, c.id, true)
				stopped = stopped + 1
			end
		end
		if stopped > 0 then
			M.restart_attached()
			vim.notify(("Stopped %d '%s' client(s) and reinitialized"):format(stopped, input))
		else
			vim.notify(("No active client found named '%s'"):format(input), vim.log.levels.WARN)
		end
	end)
end

return M
