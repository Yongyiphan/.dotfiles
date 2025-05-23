local dap = require("dap")
local OpenDebugAD7_path = vim.fn.stdpath("data") .. "/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7"

dap.adapters.cppdbg = {
	id = "cppdbg",
	type = "executable",
	command = OpenDebugAD7_path,
}
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

dap.configurations.cpp = {
	{
		name = "C/C++ executable",
		type = "cppdbg",
		request = "launch",
		cwd = "${workspaceFolder}",
		program = function()
			return coroutine.create(function(coro)
				local opts = {}
				pickers
						.new(opts, {
							prompt_title = "Path to executable",
							finder = finders.new_oneshot_job({ "fd", "--hidden", "--no-ignore", "--type", "x" }, {}),
							sorter = conf.generic_sorter(opts),
							attach_mappings = function(buffer_number)
								actions.select_default:replace(function()
									actions.close(buffer_number)
									coroutine.resume(coro, action_state.get_selected_entry()[1])
								end)
								return true
							end,
						})
						:find()
			end)
		end,
	},
}

dap.configurations.c = dap.configurations.cpp
if vim.fn.filereadable(".vscode/launch.json") then
	-- require("dap.ext.vscode").load_launchjs()
end
