vim.g.mapleader = " "
--TODO
--On First Set Up
--Add Main_Dir
--Update /ignore/.fdignore_main

_G.Main_Dir = "/mnt/c/Users/edgar/"
_G.Setup_Status = true
_G.cwd = vim.fn.expand("%:p:h")
_G.lua_version = "5.4"

require("ega.core")
print("Complete Init")

if _G.Setup_Status then
	vim.cmd('call feedkeys("\\<CR>")')
end

--vim.api.nvim_create_autocmd("VimEnter", {
--	callback = function()
--		vim.api.nvim_buf_delete(0, { force = true })
--		_G.t_find_files()
--	end,
--})
