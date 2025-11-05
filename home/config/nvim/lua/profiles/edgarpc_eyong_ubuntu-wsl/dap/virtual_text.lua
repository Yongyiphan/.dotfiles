local virtual_text = _G.call("nvim-dap-virtual-text")
if not virtual_text then
	return
end

virtual_text.setup({
	-- enable this plugin (the default)
	enabled = true,
	-- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
	enabled_commands = true,
	-- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
	highlight_changed_variables = true,
	-- highlight new variables in the same way as changed variables (if highlight_changed_variables)
	highlight_new_as_changed = false,
	-- show stop reason when stopped for exceptions
	show_stop_reason = true,
	-- prefix virtual text with comment string
	commented = false,
	-- only show virtual text at first definition (if there are multiple)
	only_first_definition = true,
	-- show virtual text on all all references of the variable (not only definitions)
	all_references = false,

	display_callback = function(variable, _buf, _stackfame, _node)
		return variable.name .. " = " .. variable.value
	end,
})

