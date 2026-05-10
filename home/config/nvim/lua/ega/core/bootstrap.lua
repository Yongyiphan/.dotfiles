-- lua/ega/core/bootstrap.lua
local uv = vim.uv or vim.loop
local M = {}

local function profile_dir(profile)
	return vim.fn.stdpath("config") .. "/lua/profiles/" .. profile
end

local function profile_exists(profile)
	return type(profile) == "string" and vim.fn.isdirectory(profile_dir(profile)) == 1
end

local function current_profile()
	local requested = vim.env.DOTFILES_PROFILE
	if profile_exists(requested) then
		return requested
	end

	local host = (uv.os_gethostname and uv.os_gethostname()) or uv.os_uname().nodename
	if profile_exists(host) then
		return host
	end

	if profile_exists("default") then
		local missing = requested or host or "unknown"
		vim.schedule(function()
			vim.notify(
				string.format("Using default Neovim profile because '%s' does not exist.", missing),
				vim.log.levels.WARN
			)
		end)
		return "default"
	end

	error("No Neovim profile directory found for requested profile, host, or default.")
end

function M.init()
	local profile = current_profile()
	local cfg = vim.fn.stdpath("config")

	vim.g.NVIM_PROFILE = profile
	vim.g.NVIM_LOCKFILE = cfg .. "/locks/lazy-lock-" .. profile .. ".json"

	_G.profile = profile
	_G.rprofile = "profiles." .. profile

	return {
		profile = profile,
		pdir = profile_dir(profile),
		lockfile = vim.g.NVIM_LOCKFILE,
	}
end

return M
