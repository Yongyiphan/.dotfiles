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
	{ import = ("profiles.%s.plugins"):format(profile) },
}

-- Set global profile reference for plugins that need it

-- -- Get list of enabled languages for current profile
-- local ok, profile_lsp_settings = pcall(require, ("profiles.%s.lsp.settings"):format(profile))
--
-- if ok and profile_lsp_settings and type(profile_lsp_settings.languages) == "table" then
-- 	for _, lang in ipairs(profile_lsp_settings.languages) do
-- 		local lang_ok, lang_def = pcall(require, ("ega.custom.lsp.settings.%s"):format(lang))
-- 		
-- 		if lang_ok and lang_def and type(lang_def.plugins) == "table" then
-- 			-- Insert all plugin specs from this language
-- 			vim.list_extend(specs, lang_def.plugins)
-- 			print(string.format("[LSP] ✅ Added %d plugins for %s", #lang_def.plugins, lang))
-- 		end
-- 	end
-- else
-- 	vim.notify(string.format("[LSP] No languages configured for profile '%s'", profile), vim.log.levels.WARN)
-- end


lazy.setup(specs, {
	lockfile = vim.g.NVIM_LOCKFILE,
	ui = { border = "rounded" }
})

require("ega.core.remap")

vim.cmd("colorscheme nightfox")
-- vim.cmd([[colorscheme tokyonight]])
print("Complete ega.core Init")
