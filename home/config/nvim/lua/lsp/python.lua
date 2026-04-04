---@type LanguageProfile
local FullProfile = vim.deepcopy(require("profiles.template.lsp.settings_template"))

local S = FullProfile.settings
-- identity / scope
S.meta.lang = "python"
S.files.filetypes = { "python" }

local function detect_venv_root()
	-- List of common virtual environment directory names
	local venv_names = { ".venv", ".env", "venv", "env", ".virtualenv" }
	
	-- Start from current buffer's directory (most accurate for project context)
	local start_dir = vim.fn.expand("%:p:h")
	local current_dir = vim.fn.fnamemodify(start_dir, ":p")
	
	print("[VENV] Searching from:", current_dir) -- Debug output
	
	while current_dir and current_dir ~= "/" do
		for _, venv_name in ipairs(venv_names) do
			local venv_path = current_dir .. "/" .. venv_name
			local activate_path = venv_path .. "/bin/activate"

			
			-- Check if activate script exists (most reliable venv indicator)
			if vim.fn.filereadable(activate_path) == 1 then
				local bin_path = venv_path .. "/bin"
				print("[VENV] ✓ Found:", bin_path)
				return bin_path
			end
		end
		
		-- Move to parent directory
		local parent_dir = vim.fn.fnamemodify(current_dir, ":h")
		if parent_dir == current_dir then
			break
		end
		current_dir = parent_dir
	end
	
	print("[VENV] ✗ Not found, using system PATH")
	return nil
end

-- LSP: pyright
S.lsp.pyright = {
	enabled = true,
	cmd = { "pyright-langserver", "--stdio" },
	root_dir_markers = { "pyproject.toml", "setup.cfg", "setup.py", ".pylintrc", ".git" },
	filetypes = { "python" },
	settings = {
		python = {
			venvPath = ".", -- project root
			venv = ".venv", -- use .venv in project
			analysis = {
				typeCheckingMode = "basic",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				extraPaths = { "." }, -- make root importable
			},
		},
	},
}

-- use null-ls path
S.use_none_ls = true
S.none_ls = {
	formatting = { "black", "isort" },
	diagnostics = { "pylint", "mypy" },
	code_actions = { "refactoring" },
}

-- format-on-save
S.format_on_save.enable = false
S.format_on_save.vars = { line_length = 100, force_line_length = false }

-- Provide all null-ls sources with correct config
S.hooks.none_ls_sources = function(builtins)
  local venv_bin = detect_venv_root()

  -- Resolve venv python explicitly (prefer python3, fallback to python)
  local venv_python = nil
  if venv_bin then
    local p3 = venv_bin .. "/python3"
    local p  = venv_bin .. "/python"
    if vim.fn.executable(p3) == 1 then
      venv_python = p3
    elseif vim.fn.executable(p) == 1 then
      venv_python = p
    end
  end

  -- Prefer using pyproject.toml. Only set line length if you want an override.
  local black_args = {}
  local isort_args = { "--profile", "black" }

  if S.format_on_save and S.format_on_save.vars and S.format_on_save.vars.force_line_length then
    local ll = tostring(S.format_on_save.vars.line_length or 100)
    black_args = { "--line-length", ll }
    isort_args = { "--profile", "black", "--line-length", ll }
  end

  -- Pylint:
  -- If venv found, force: <venv_python> -m pylint ...
  -- Else fallback to system pylint.
  local pylint_source
  if venv_python then
    pylint_source = builtins.diagnostics.pylint.with({
			command = venv_bin and (venv_bin .. "/pylint") or "pylint",
			extra_args = {
				"--init-hook",
				"import os, sys; sys.path.insert(0, os.getcwd())",
				"--rcfile",
				"pyproject.toml",
    },
  })
  else
    pylint_source = builtins.diagnostics.pylint.with({
      -- fallback to PATH pylint
      extra_args = {
        "--init-hook", "import os, sys; sys.path.insert(0, os.getcwd())",
        "--rcfile=pyproject.toml",
      },
    })
  end

  -- Mypy: only pass --python-executable if venv found
  local mypy_extra = {}
  if venv_python then
    mypy_extra = { "--python-executable", venv_python }
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
      extra_args = mypy_extra,
    }),
    builtins.code_actions.refactoring,
  }
end

-- keep default none-ls on_attach (your pipeline wraps its own anyway)
S.hooks.none_ls_on_attach = function(_, _) return true end

-- (Optional) disable external installer since we’re using local venv/tools
S.installer.enabled = false

return FullProfile
