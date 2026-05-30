local python_root_markers = {
	"pyrightconfig.json",
	"pyproject.toml",
	"setup.cfg",
	"setup.py",
	"requirements.txt",
	"Pipfile",
	"tox.ini",
	"pylintrc",
	".pylintrc",
	".git",
}

local function resolve_start_dir(path)
	local target = path
	if type(target) ~= "string" or target == "" then
		target = vim.api.nvim_buf_get_name(0)
	end
	if target == "" then
		target = vim.uv.cwd()
	end

	target = vim.fn.fnamemodify(target, ":p")
	if vim.fn.filereadable(target) == 1 then
		return vim.fs.dirname(target)
	end

	return target
end

local function detect_venv_root(path)
	local venv_names = { ".venv", ".env", "venv", "env", ".virtualenv" }
	local current_dir = resolve_start_dir(path)

	while current_dir and current_dir ~= "/" do
		for _, venv_name in ipairs(venv_names) do
			local venv_path = current_dir .. "/" .. venv_name
			local activate_path = venv_path .. "/bin/activate"
			if vim.fn.filereadable(activate_path) == 1 then
				return venv_path
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

local function resolve_python_env(path)
	local venv_root = detect_venv_root(path)
	local venv_bin = venv_root and (venv_root .. "/bin") or nil
	local python3 = venv_bin and (venv_bin .. "/python3") or nil
	local python = venv_bin and (venv_bin .. "/python") or nil
	local venv_python = nil

	if python3 and vim.fn.executable(python3) == 1 then
		venv_python = python3
	elseif python and vim.fn.executable(python) == 1 then
		venv_python = python
	end

	return {
		venv_root = venv_root,
		venv_bin = venv_bin,
		venv_name = venv_root and vim.fs.basename(venv_root) or nil,
		venv_parent = venv_root and vim.fs.dirname(venv_root) or nil,
		venv_python = venv_python,
	}
end

local function resolve_python_tool(path, tool)
	local env = resolve_python_env(path)
	local local_tool = env.venv_bin and (env.venv_bin .. "/" .. tool) or nil

	if local_tool and vim.fn.executable(local_tool) == 1 then
		return local_tool
	end

	if vim.fn.executable(tool) == 1 then
		return tool
	end

	return nil
end

local function resolve_python_root(path)
	local start_dir = resolve_start_dir(path)
	return vim.fs.root(start_dir, python_root_markers)
end

local function python_tool_command(tool)
	return function(params, done)
		done(resolve_python_tool(params.bufname, tool))
	end
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
			root_dir_markers = python_root_markers,
			condition = function(ctx)
				return resolve_python_env(ctx.bufname).venv_python ~= nil
			end,
			settings = function(ctx)
				local env = resolve_python_env(ctx.bufname)
				local root_dir = resolve_python_root(ctx.bufname) or ctx.root_dir
				local settings = {
					python = {
						analysis = {
							typeCheckingMode = "basic",
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
							extraPaths = root_dir and { root_dir } or { "." },
						},
					},
				}

				-- Pyright's analysis is only useful when it sees the project interpreter.
				if env.venv_python then
					settings.python.pythonPath = env.venv_python
				end
				if env.venv_parent and env.venv_name then
					settings.python.venvPath = env.venv_parent
					settings.python.venv = env.venv_name
				end

				return settings
			end,
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
			local isort_args = { "--profile", "black" }

			return {
				builtins.formatting.black.with({
					dynamic_command = python_tool_command("black"),
				}),
				builtins.formatting.isort.with({
					dynamic_command = python_tool_command("isort"),
					extra_args = isort_args,
				}),
				builtins.diagnostics.pylint.with({
					dynamic_command = python_tool_command("pylint"),
					extra_args = {
						"--init-hook",
						"import os, sys; sys.path.insert(0, os.getcwd())",
					},
					runtime_condition = function(params)
						return resolve_python_tool(params.bufname, "pylint") ~= nil
					end,
				}),
				builtins.diagnostics.mypy.with({
					dynamic_command = python_tool_command("mypy"),
					extra_args = function(params)
						local env = resolve_python_env(params.bufname)
						if env.venv_python then
							return { "--python-executable", env.venv_python }
						end
						return {}
					end,
					runtime_condition = function(params)
						return resolve_python_tool(params.bufname, "mypy") ~= nil
					end,
				}),
				builtins.code_actions.refactoring,
			}
		end,
	},
	plugins = {},
}
