local telescope = _G.call("telescope")
if not telescope then
	return
end

local builtin = require("telescope.builtin")
local fb_actions = require("telescope._extensions.file_browser.actions")
local fb_lsp = require("telescope._extensions.file_browser.lsp")
local action_state = require("telescope.actions.state")
local lsp_utils = require("ega.custom.lsp.utils")
local Utils = require("ega.core.utils")
local M = {}
local show_hidden_files = false
M.builtin = builtin
M.telescope = telescope

-- Get selected entries from the current picker
M.get_selected_entries = function(prompt_bufnr)
	local action_state = require("telescope.actions.state")
	local picker = action_state.get_current_picker(prompt_bufnr)
	local current_entry = action_state.get_selected_entry()
	local selections = { current_entry }
	-- Add multiple selections if applicable
	for _, entry in ipairs(picker:get_multi_selection()) do
		if not vim.tbl_contains(selections, entry) then
			table.insert(selections, entry)
		end
	end
	return selections
end

-- Open PDF using external script
M.open_pdf_with_script = function(entry)
	local script_path = "$HOME/.config/nvim/scripts/open_edge.sh"
	local selection = Utils.convert_path_to_windows(entry)
	if selection then
		local cmd = string.format("%s %s", script_path, selection)
		local status = vim.fn.system(cmd)
		assert(status ~= 0, "Error: Unable to open PDF: " .. vim.fn.fnamemodify(entry, ":t"))
	else
		print("Not a Windows file")
	end
end

-- Open selected file or PDF
M.open_selected_file = function(prompt_bufnr)
	local selections = M.get_selected_entries(prompt_bufnr)
	for _, entry in ipairs(selections) do
		if vim.fn.fnamemodify(entry.value, ":e") == "pdf" then
			M.open_pdf_with_script(entry.path)
		end
		require("telescope.actions").close(prompt_bufnr)
	end
end

-- Unzip selected files
M.unzip_selected_file = function(prompt_bufnr)
	local function unzip_file(filename, destination)
		local command = string.format("unzip %s -d %s", vim.fn.shellescape(filename), vim.fn.shellescape(destination))
		vim.fn.system(command)
	end
	local selections = M.get_selected_entries(prompt_bufnr)
	for _, entry in ipairs(selections) do
		local current_file = vim.fn.fnamemodify(entry.path, ":t")
		local extension = current_file:match("%.([^%.]+)$")
		if extension == "zip" then
			local filename = current_file:gsub("%.[^.]*$", "")
			unzip_file(current_file, ".//" .. filename .. "//")
		end
	end
	require("telescope.actions").close(prompt_bufnr)
	M.open_file_explorer()
end

-- Find files without ignoring .gitignore
M.find_files_no_ignore = function(prompt_bufnr)
	local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
	local opts = {
		hidden = false,
		respect_gitignore = false,
		default_text = current_picker:_get_prompt(),
		no_ignore = true
	}
	require("telescope.actions").close(prompt_bufnr)
	require("telescope.builtin").find_files(opts)
end

-- Function to toggle showing hidden files
M.toggle_hidden_files = function(prompt_bufnr)
	-- Toggle the hidden files state
	show_hidden_files = not show_hidden_files
	local opts = {
		cwd = vim.loop.cwd(),
		hidden = show_hidden_files,
		respect_gitignore = false,
	}
	-- Update the UI with the new hidden files state
	require("telescope.actions").close(prompt_bufnr)
	telescope.extensions.file_browser.file_browser(opts)
end

-- Move to the parent directory and find files
M.find_files_in_parent_directory = function(prompt_bufnr)
	local opts = {}
	opts.find_command = {
		"fd",
		"--type",
		"f",
		"--ignore-file",
		"$HOME/.config/nvim/ignore/.general_ignore",
		"--ignore-file",
		"$HOME/.config/nvim/ignore/.tele_ignore",
	}
	
	_G.cwd = vim.fn.fnamemodify(_G.cwd, ":h")
	opts.cwd = _G.cwd
	
	require("telescope.actions").close(prompt_bufnr)
	require("telescope.builtin").find_files(opts)
end

local function file_browser_base_dir(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local finder = picker.finder
	local entry = action_state.get_selected_entry()

	if finder.files then
		return finder.path, picker, finder
	end
	if entry and entry.value then
		return entry.value, picker, finder
	end
	return finder.cwd or vim.loop.cwd(), picker, finder
end

local function resolve_file_browser_input(input, base_dir)
	if not input or input == "" then
		return nil
	end
	if input:sub(1, 1) == "/" then
		return vim.fn.fnamemodify(input, ":p")
	end
	return vim.fn.fnamemodify(base_dir .. "/" .. input, ":p")
end

M.create_file_browser_entry = function(prompt_bufnr)
	local base_dir, picker, finder = file_browser_base_dir(prompt_bufnr)
	local default_path = base_dir .. "/"

	vim.ui.input({ prompt = "Create: ", default = default_path, completion = "file" }, function(input)
		local path = resolve_file_browser_input(input, base_dir)
		if not path then
			return
		end
		if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
			vim.notify("Selection already exists: " .. path, vim.log.levels.WARN)
			return
		end

		fb_lsp.will_create_files({ path })
		if path:sub(-1) == "/" then
			vim.fn.mkdir(path, "p")
		else
			vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
			vim.fn.writefile({}, path)
		end
		fb_lsp.did_create_files({ path })

		lsp_utils.notify_file_operation({
			{ uri = vim.uri_from_fname(path), type = 1 },
		})
		picker:refresh(finder, { reset_prompt = true, multi = picker._multi })
	end)
end

M.rename_file_browser_entry = function(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local finder = picker.finder
	local entry = action_state.get_selected_entry()
	if not entry or not entry.path then
		return
	end

	local old_path = vim.fn.fnamemodify(entry.path, ":p")
	vim.ui.input({ prompt = "Rename: ", default = old_path, completion = "file" }, function(input)
		local new_path = resolve_file_browser_input(input, vim.fn.fnamemodify(old_path, ":h"))
		if not new_path or new_path == old_path then
			return
		end

		fb_lsp.will_rename_files({ [old_path] = new_path })
		local ok = vim.fn.rename(old_path, new_path) == 0
		if not ok then
			vim.notify("Rename failed: " .. old_path, vim.log.levels.ERROR)
			return
		end
		fb_lsp.did_rename_files({ [old_path] = new_path })

		lsp_utils.notify_file_operation({
			{ uri = vim.uri_from_fname(old_path), type = 3 },
			{ uri = vim.uri_from_fname(new_path), type = 1 },
		})
		picker:refresh(finder, { reset_prompt = true, multi = picker._multi })
	end)
end

-- File explorer: show all files, including hidden ones
M.show_all_files_in_explorer = function(prompt_bufnr)
	local opts = {
		cwd = vim.loop.cwd(),
		hidden = true,
		respect_gitignore = false,
		no_ignore = true
	}
	
	require("telescope.actions").close(prompt_bufnr)
	telescope.extensions.file_browser.file_browser(opts)
end

-- Open file explorer with custom options
M.open_file_explorer = function(browser_dir)
	local opts = {
		cwd = browser_dir or vim.loop.cwd(),
		hidden = true,
		respect_gitignore = false,
		follow = true,
	}
	
	telescope.extensions.file_browser.file_browser(opts)
end

-- Telescope setup with mappings and extensions
telescope.setup({
	defaults = {
		mappings = {
			n = {
				["<C-o>"] = M.open_selected_file,
			},
			i = {
				["<C-o>"] = M.open_selected_file,
			},
		},
	},
	pickers = {
		find_files = {
			mappings = {
				n = {
					["<S-p>"] = M.find_files_in_parent_directory,
					["h"] = M.find_files_no_ignore,
				},
			},
		},
	},
	extensions = {
		file_browser = {
			initial_mode = "normal",
			multi_icon = "*",
			sorting_strategy = "ascending",
			layout_config = {
				prompt_position = "top",
			},
			display_stat = {
				date = true,
				size = false,
				mode = false,
			},
			grouped = true,
			git_status = false,
			hidden = true,
			use_fd = true,
			follow = true,
			mappings = {
				["n"] = {
					["]"] = fb_actions.toggle_respect_gitignore,
					["c"] = M.create_file_browser_entry,
					["d"] = fb_actions.remove,
					["m"] = fb_actions.move,
					["r"] = M.rename_file_browser_entry,
					["z"] = M.unzip_selected_file,
					["h"] = M.show_all_files_in_explorer,
				},
			},
		},
		fzf = {
			fuzzy = true,
			override_generic_sorter = true,
			override_file_sorter = true,
			case_mode = "smart_case",
		},
		media_files = {
			find_cmd = "rg",
		},
	},
})

-- Find files with custom command
M.find_files_custom = function(cwd, opts)
	_G.cwd = vim.fn.expand("%:p:h")
	opts = opts or {
		cwd = cwd or vim.loop.cwd(),
	}
	opts.find_command = { "fd", "--type", "f", "--ignore-file", "$HOME/.config/nvim/ignore/.tele_ignore" }
	builtin.find_files(opts)
end

-- Live grep files
M.live_grep_files = function()
	builtin.live_grep()
end

telescope.load_extension("file_browser")
telescope.load_extension("media_files")
telescope.load_extension("fzf")
telescope.load_extension("dap")

return M
