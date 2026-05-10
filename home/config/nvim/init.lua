require("ega.core.bootstrap").init()

vim.g.mapleader = " "
vim.g._lsp_boot_done = false

_G.Main_Dir = vim.env.MAIN_DIR or (vim.uv or vim.loop).os_homedir()
_G.cwd = vim.fn.getcwd()

require("ega.core")
