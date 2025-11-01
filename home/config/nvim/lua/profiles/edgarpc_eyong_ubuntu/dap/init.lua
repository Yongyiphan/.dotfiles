local M = {}
local dap, dapui = _G.call("dap"), _G.call("dapui")
if not dap then
	return M
end
if not dapui then
	return M
end

local ensure_installed = {
	"debugpy",
}
require("mason-nvim-dap").setup({
	ensure_installed = ensure_installed,
})

require(_G.rprofile .. ".dap.settings.luad")
require(_G.rprofile .. ".dap.settings.pythond")
require(_G.rprofile .. ".dap.settings.cppd")

dapui.setup({
	layouts = {
		{
			elements = {
				{ id = "scopes",      size = 20 },
				"stacks",
				{ id = "breakpoints", size = 0.2 },
			},
			size = 40,
			position = "left",
		},
		{
			elements = {
				"repl",
				"console",
			},
			size = 0.25,
			position = "bottom",
		},
	},
})

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open({
		reset = true,
	})
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

require(_G.rprofile .. ".dap.virtual_text")

M.keybinding = {}
M.keybinding.setup = function()
	require(_G.profile .. ".dap.keybinding")
end

return M
