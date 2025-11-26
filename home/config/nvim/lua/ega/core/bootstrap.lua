-- lua/ega/core/bootstrap.lua
local uv = vim.uv or vim.loop
local M = {}

local function current_profile()
	local host = (uv.os_gethostname and uv.os_gethostname()) or uv.os_uname().nodename
	return vim.env.DOTFILES_PROFILE or host or "default"
end

function M.init(opts)
	opts          = opts or {}
	local PROFILE = current_profile()
	local CFG     = vim.fn.stdpath("config")          -- ~/.config/nvim
	local PDIR    = CFG .. "/lua/profiles/" .. PROFILE -- fixed slash
	local LDIR    = CFG .. "/locks"
	
	if vim.fn.isdirectory(PDIR) == 0 then
		print("Creating PDIR: ", PDIR)
		vim.fn.mkdir(PDIR, "p")
	end
	
	if vim.fn.isdirectory(LDIR) == 0 then
		print("Creating LDIR: ", LDIR)
		vim.fn.mkdir(LDIR, "p")
	end
	
	-- export for later (lazy lockfile, etc.)
	vim.g.NVIM_PROFILE = PROFILE
	vim.g.NVIM_LOCKFILE = LDIR .. "/lazy-lock-" .. PROFILE .. ".json"
	
	-- optional scaffolding
	if opts.scaffold then
		for _, sub in ipairs({ "lsp", "dap", "dap/plugins", "dap/settings" }) do
			local d = PDIR .. "/" .. sub
			if vim.fn.isdirectory(d) == 0 then
				vim.fn.mkdir(d, "p")
			end
			local i = PDIR .. "/" .. sub .. "/init.lua"
			if vim.fn.filereadable(i) == 0 then
				vim.fn.writefile({}, i)
			end
		end
	end
	
	-- 1) helper: write content only if file is missing or empty
	local function write_if_missing_or_empty(path, content)
		local exists = vim.fn.filereadable(path) == 1
		local empty = true
		if exists then
			local ok, lines = pcall(vim.fn.readfile, path)
			empty = (not ok) or (#lines == 0)
		end
		if (not exists) or empty then
			vim.fn.writefile(vim.split(content, "\n", { plain = true }), path)
		end
	end
	
	-- 2) stubs for settings init.lua (so require() returns a table, not `true`)
	local SETTINGS_STUB = table.concat({
		"local M = {}",
		"local names = {}",
		"M.names = names",
		"return M",
		"",
	}, "\n")
	
	-- only these two get content; others can stay blank
	write_if_missing_or_empty(PDIR .. "/dap/settings/init.lua", SETTINGS_STUB)
	
	_G.profile = PROFILE
	_G.rprofile = "profiles." .. PROFILE
	return { profile = PROFILE, pdir = PDIR, locks = LDIR }
end

return M
