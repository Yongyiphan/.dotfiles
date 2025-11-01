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
	{ import = ("profiles.%s.lsp.plugins"):format(profile) },
	{ import = ("profiles.%s.dap.plugins"):format(profile) },
}

lazy.setup(specs, {
	lockfile = vim.g.NVIM_LOCKFILE,
	ui = { border = "rounded" }
})

require("ega.core.remap")

vim.cmd("colorscheme nightfox")
-- vim.cmd([[colorscheme tokyonight]])
print("Complete ega.core Init")
