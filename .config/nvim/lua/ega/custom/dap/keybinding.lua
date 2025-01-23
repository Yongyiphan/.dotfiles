local dap, dapui = _G.call("dap"), _G.call("dapui")
if not dap then
	print(vim.api.nvim_buf_get_name(0))
	return
end
if not dapui then
	print(vim.api.nvim_buf_get_name(0))
	return
end
local vmap = vim.keymap.set
local continue = function()
	if vim.fn.filereadable(".vscode/launch.json") then
		require("dap.ext.vscode").load_launchjs(nil, { cppdbg = { "c", "cpp" } })
	end
	require("dap").continue()
end

--vmap("n", "<leader>1", _G.dap_start, { noremap = true })
--vmap("n", "<leader>2", _G.dap_stop, { noremap = true })
vmap("n", "<leader>db", dap.toggle_breakpoint, _G.KeyOpts("Toggle Breakpoint"))
vmap("n", "<leader>dB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, _G.KeyOpts("Conditional Breakpoint"))
vmap("n", "<leader>dc", "<cmd>Telescope dap configurations<CR>", _G.KeyOpts("Configs"))
vmap("n", "<leader>dt", dap.terminate, _G.KeyOpts("Terminate"))

vmap("n", "<F5>", dap.continue, _G.KeyOpts("Continue"))
vmap("n", "<F9>", dap.step_over, _G.KeyOpts("Step-over"))
vmap("n", "<F10>", dap.step_into, _G.KeyOpts("Step-into"))
vmap("n", "<F8", dap.step_out, _G.KeyOpts("Step-out"))

vmap("n", "<leader>dsc", continue, _G.KeyOpts("Continue"))
vmap("n", "<leader>dsv", dap.step_over, _G.KeyOpts("Step Over"))
vmap("n", "<leader>dsi", dap.step_into, _G.KeyOpts("Step Into"))
vmap("n", "<leader>dso", dap.step_out, _G.KeyOpts("Step Out"))

vmap("n", "<leader>dhh", ":lua require('dap.ui.variables').hover()<CR>")
vmap("v", "<leader>dhv", ":lua require('dap.ui.variables').visual_hover()<CR>")

--Dap UI
vmap("n", "<leader>di", dapui.toggle, _G.KeyOpts("UI Toggle"))
