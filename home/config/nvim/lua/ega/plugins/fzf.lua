local ogfzf = {
	--"junegunn/fzf",
	--build = {
	--	"./install --bin",
	--}
}
local fl = {
	"ibhagwan/fzf-lua",
	branch = "main",
	config = function()
		require("fzf-lua").setup({})
		_G.call("ega.custom.fzflua")
	end,
}

return { ogfzf, fl }
