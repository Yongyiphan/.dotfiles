local M = {}

M.setup = function()
	local treesitter = _G.call("nvim-treesitter.configs")
	if not treesitter then
		return
	end
	treesitter.setup({
		auto_install = true,
		highlight = {
			enable = true,
		},
	})

	local comments = require("Comment")
comments.setup()
end

return M
