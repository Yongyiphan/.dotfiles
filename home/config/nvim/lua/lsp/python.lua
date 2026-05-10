local function detect_venv_root()
	local venv_names = { ".venv", ".env", "venv", "env", ".virtualenv" }
	local start_dir = vim.fn.expand("%:p:h")
	local current_dir = vim.fn.fnamemodify(start_dir, ":p")

	while current_dir and current_dir ~= "/" do
		for _, venv_name in ipairs(venv_names) do
			local venv_path = current_dir .. "/" .. venv_name
			local activate_path = venv_path .. "/bin/activate"
			if vim.fn.filereadable(activate_path) == 1 then
				return venv_path .. "/bin"
			end
		end

		local parent_dir = vim.fn.fnamemodify(current_dir, ":h")
		if parent_dir == current_dir then
			break
		end
		current_dir = parent_dir
	end
	return nil
end

return {
	meta = {
		name = "python",
		filetypes = { "python" },
	},
	lsp = {
		pyright = {
			enabled = true,
			cmd = { "pyright-langserver", "--stdio" },
			root_dir_markers = { "pyproject.toml", "setup.cfg", "setup.py", ".pylintrc", ".git" },
			settings = {
				python = {
					venvPath = ".",
					venv = ".venv",
					analysis = {
						typeCheckingMode = "basic",
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						extraPaths = { "." },
					},
				},
			},
		},
	},
	install = {
		mason = { "pyright", "black", "isort", "mypy", "pylint" },
		system = {
			apt = { "nodejs", "npm", "python3", "python3-venv" },
			dnf = { "nodejs", "npm", "python3" },
			pacman = { "nodejs", "npm", "python" },
			brew = { "node", "python" },
		},
		project_local = {
			tools = { "black", "isort", "mypy", "pylint" },
			note = "Project virtual environments are preferred when present.",
		},
	},
	editor = {
		format_on_save = {
			enabled = false,
		},
		none_ls_sources = function(builtins)
			local venv_bin = detect_venv_root()
			local venv_python = nil
			if venv_bin then
				local python3 = venv_bin .. "/python3"
				local python = venv_bin .. "/python"
				if vim.fn.executable(python3) == 1 then
					venv_python = python3
				elseif vim.fn.executable(python) == 1 then
					venv_python = python
				end
			end

			local black_args = {}
			local isort_args = { "--profile", "black" }

			local pylint_source
			if venv_python then
				pylint_source = builtins.diagnostics.pylint.with({
					command = venv_bin .. "/pylint",
					extra_args = {
						"--init-hook",
						"import os, sys; sys.path.insert(0, os.getcwd())",
						"--rcfile",
						"pyproject.toml",
					},
				})
			else
				pylint_source = builtins.diagnostics.pylint.with({
					extra_args = {
						"--init-hook",
						"import os, sys; sys.path.insert(0, os.getcwd())",
						"--rcfile=pyproject.toml",
					},
				})
			end

			local mypy_args = {}
			if venv_python then
				mypy_args = { "--python-executable", venv_python }
			end

			return {
				builtins.formatting.black.with({
					prefer_local = venv_bin,
					extra_args = black_args,
				}),
				builtins.formatting.isort.with({
					prefer_local = venv_bin,
					extra_args = isort_args,
				}),
				pylint_source,
				builtins.diagnostics.mypy.with({
					prefer_local = venv_bin,
					extra_args = mypy_args,
				}),
				builtins.code_actions.refactoring,
			}
		end,
	},
	plugins = {},
}
