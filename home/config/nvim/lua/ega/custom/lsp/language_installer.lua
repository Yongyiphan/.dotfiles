local M = {}

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO)
end

local function append_unique(list, value)
	if type(value) ~= "string" or value == "" then
		return
	end
	if not vim.tbl_contains(list, value) then
		table.insert(list, value)
	end
end

local function detect_package_manager()
	if vim.fn.executable("apt-get") == 1 then
		return "apt"
	end
	if vim.fn.executable("dnf") == 1 then
		return "dnf"
	end
	if vim.fn.executable("pacman") == 1 then
		return "pacman"
	end
	if vim.fn.executable("brew") == 1 then
		return "brew"
	end
	return nil
end

local function render_requirements(requirements, opts)
	opts = opts or {}
	local lines = {
		string.format("Profile: %s", opts.profile or vim.g.NVIM_PROFILE or "default"),
		string.format("Package manager: %s", requirements.manager or "none"),
		string.format("Mason packages: %s", #requirements.mason > 0 and table.concat(requirements.mason, ", ") or "(none)"),
		string.format("System packages: %s", #requirements.system > 0 and table.concat(requirements.system, ", ") or "(none)"),
	}

	if #requirements.project_local == 0 then
		table.insert(lines, "Project-local tools: (none)")
	else
		table.insert(lines, "Project-local tools:")
		for _, entry in ipairs(requirements.project_local) do
			local line = string.format("- %s: %s", entry.language, table.concat(entry.tools, ", "))
			if entry.note and entry.note ~= "" then
				line = line .. " (" .. entry.note .. ")"
			end
			table.insert(lines, line)
		end
	end

	return lines
end

function M.collect_requirements(definitions)
	local manager = detect_package_manager()
	local requirements = {
		manager = manager,
		mason = {},
		system = {},
		project_local = {},
	}

	for _, def in ipairs(definitions or {}) do
		local install = def.install or {}

		for _, pkg in ipairs(install.mason or {}) do
			append_unique(requirements.mason, pkg)
		end

		if manager and type(install.system) == "table" then
			for _, pkg in ipairs(install.system[manager] or {}) do
				append_unique(requirements.system, pkg)
			end
		end

		local project_local = install.project_local
		if type(project_local) == "table" then
			local tools = project_local.tools or project_local
			if type(tools) == "table" and #tools > 0 then
				table.insert(requirements.project_local, {
					language = (def.meta and def.meta.name) or "unknown",
					tools = vim.deepcopy(tools),
					note = project_local.note,
				})
			end
		end
	end

	table.sort(requirements.mason)
	table.sort(requirements.system)
	table.sort(requirements.project_local, function(left, right)
		return left.language < right.language
	end)

	return requirements
end

function M.show_requirements(definitions, opts)
	local lines = render_requirements(M.collect_requirements(definitions), opts)
	notify(table.concat(lines, "\n"))
end

local function configure_mason(packages)
	if #packages == 0 then
		return true
	end

	local mti = _G.call("mason-tool-installer")
	if not mti then
		notify("mason-tool-installer.nvim is not available.", vim.log.levels.ERROR)
		return false
	end

	mti.setup({
		ensure_installed = packages,
		run_on_start = false,
		auto_update = false,
		start_delay = 0,
		integrations = { ["mason-lspconfig"] = true },
	})

	return true
end

local function install_mason(packages)
	if #packages == 0 then
		return
	end
	if not configure_mason(packages) then
		return
	end
	local ok, err = pcall(vim.cmd, "MasonToolsInstall")
	if not ok then
		notify("Failed to start MasonToolsInstall: " .. err, vim.log.levels.ERROR)
	end
end

local function system_installer_path()
	local dotfiles = vim.env.DOTFILES or ((vim.uv or vim.loop).os_homedir() .. "/.dotfiles")
	return dotfiles .. "/setup/install-language-system-deps.sh"
end

local function install_system_packages(packages, on_success)
	local script = system_installer_path()
	if vim.fn.filereadable(script) ~= 1 then
		notify("Missing system package installer script: " .. script, vim.log.levels.ERROR)
		return
	end

	vim.cmd("botright 12split")
	local term_buf = vim.api.nvim_get_current_buf()
	local argv = { script }
	vim.list_extend(argv, packages)

	vim.fn.termopen(argv, {
		on_exit = function(_, code)
			if code == 0 then
				if on_success then
					vim.schedule(on_success)
				end
				return
			end
			vim.schedule(function()
				notify("System package installation failed.", vim.log.levels.ERROR)
			end)
		end,
	})

	vim.bo[term_buf].buflisted = false
	vim.cmd("startinsert")
end

function M.install_profile(definitions, opts)
	opts = opts or {}
	local requirements = M.collect_requirements(definitions)

	if #requirements.mason == 0 and (#requirements.system == 0 or opts.mason_only) then
		M.show_requirements(definitions, opts)
		return
	end

	local on_complete = function()
		install_mason(requirements.mason)
		if #requirements.project_local > 0 then
			local lines = render_requirements(requirements, opts)
			notify(table.concat(lines, "\n"))
		end
	end

	if opts.mason_only or #requirements.system == 0 then
		on_complete()
		return
	end

	install_system_packages(requirements.system, on_complete)
end

return M
