------------------------------
-- 				LAZY SETUP 				--
------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	print("Installing Lazy nvim...")
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

_G.Core = {
	MapGroup = {},
	LoadUpMsg = false,
}

require("ega.core.set")
require("ega.core.utils")
local lazystatus, lazy = pcall(require, "lazy")
if not lazystatus then
	return
end

local profile = vim.g.NVIM_PROFILE
local specs = {
	{ import = "ega.plugins" },
}

local lsp = require("ega.custom.lsp")
local profile_plugin_file = vim.fn.stdpath("config") .. "/lua/profiles/" .. profile .. "/plugins/init.lua"

if vim.fn.filereadable(profile_plugin_file) == 1 then
	table.insert(specs, { import = ("profiles.%s.plugins"):format(profile) })
end

for _, spec in ipairs(lsp.collect_plugin_specs()) do
	table.insert(specs, spec)
end


lazy.setup(specs, {
	lockfile = vim.g.NVIM_LOCKFILE,
	ui = { border = "rounded" }
})

require("ega.core.remap")

vim.cmd("colorscheme nightfox")
