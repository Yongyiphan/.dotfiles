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
			local venv_path = current_dir .. venv_name
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
S.format_on_save.vars = { line_length = 100 }

-- Provide all null-ls sources with correct config
S.hooks.none_ls_sources = function(builtins)
	local venv_bin = detect_venv_root()
	
	return {
		builtins.formatting.black.with({
			prefer_local = venv_bin, -- nil means system-wide
			extra_args = { "--line-length", tostring(S.format_on_save.vars.line_length or 100) },
		}),
		builtins.formatting.isort.with({
			prefer_local = venv_bin,
			extra_args = { "--profile", "black", "--line-length", tostring(S.format_on_save.vars.line_length or 100) },
		}),
		builtins.diagnostics.pylint.with({
			prefer_local = venv_bin,
			extra_args = { "--init-hook", "import sys, os; sys.path.append(os.getcwd())" },
		}),
		builtins.diagnostics.mypy.with({
			prefer_local = venv_bin,
			extra_args = { "--python-executable", (venv_bin or ""):gsub("/bin$", "") .. "/bin/python" },
		}),
		builtins.code_actions.refactoring,
	}
end

-- keep default none-ls on_attach (your pipeline wraps its own anyway)
S.hooks.none_ls_on_attach = function(_, _) return true end

-- (Optional) disable external installer since we’re using local venv/tools
S.installer.enabled = false

return FullProfile
