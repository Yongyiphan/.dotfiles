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
lazy.setup("ega.plugins", { ui = { border = "rounded" } })
require("ega.custom")
require("ega.core.remap")

vim.cmd("colorscheme nightfox")
-- vim.cmd([[colorscheme tokyonight]])
print("Complete ega.core Init")
