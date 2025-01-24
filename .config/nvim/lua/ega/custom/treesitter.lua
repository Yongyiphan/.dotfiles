local treesitter = _G.call("nvim-treesitter.configs")
if not treesitter then
	return
end
treesitter.setup({
	ensure_installed = {
		"c",
		"lua",
		"vim",
		"cpp",
		"asm",
	},
	highlight = {
		enable = true,
	},
	auto_install = true,
	--	highlight = {
	--		enable = true,
	--	},
})

local comments = require("Comment")
comments.setup()
