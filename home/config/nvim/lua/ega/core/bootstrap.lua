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
	vim.g.NVIM_PROFILE  = PROFILE
	vim.g.NVIM_LOCKFILE = LDIR .. "/lazy-lock-" .. PROFILE .. ".json"
	
	-- optional scaffolding
	if opts.scaffold then
		for _, sub in ipairs({ "lsp", "lsp/plugins", "lsp/settings", "dap", "dap/plugins", "dap/settings" }) do
			local d = PDIR .. "/" .. sub
			if vim.fn.isdirectory(d) == 0 then vim.fn.mkdir(d, "p") end
			local i = PDIR .. "/" .. sub .. "/init.lua"
			if vim.fn.filereadable(i) == 0 then
				vim.fn.writefile({}, i)
			end
		end
	end
	
	_G.profile = PROFILE
	_G.rprofile = "profiles." .. PROFILE
	return { profile = PROFILE, pdir = PDIR, locks = LDIR }
end

return M
