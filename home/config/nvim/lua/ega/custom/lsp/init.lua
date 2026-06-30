local M = {}

local function unique_languages(languages)
	local out = {}
	local seen = {}
	for _, lang in ipairs(languages or {}) do
		if type(lang) == "string" and lang ~= "" and not seen[lang] then
			seen[lang] = true
			table.insert(out, lang)
		end
	end
	return out
end

function M.get_enabled_languages()
	local ok, profile_settings = pcall(require, string.format("profiles.%s.lsp", vim.g.NVIM_PROFILE))
	if ok and type(profile_settings) == "table" and type(profile_settings.languages) == "table" then
		local langs = unique_languages(profile_settings.languages)
		if #langs > 0 then
			return langs
		end
	end

	local ok_default, default_settings = pcall(require, "profiles.default.lsp")
	if ok_default and type(default_settings) == "table" and type(default_settings.languages) == "table" then
		local langs = unique_languages(default_settings.languages)
		if #langs > 0 then
			return langs
		end
	end

	return { "lua_ls" }
end

function M.load_language(lang)
	local ok, def = pcall(require, "lsp." .. lang)
	if not ok or type(def) ~= "table" then
		vim.notify(string.format("Failed to load language definition 'lsp.%s'", lang), vim.log.levels.ERROR)
		return nil
	end
	return def
end

function M.get_active_definitions()
	local defs = {}
	for _, lang in ipairs(M.get_enabled_languages()) do
		local def = M.load_language(lang)
		if def then
			table.insert(defs, def)
		end
	end
	return defs
end

function M.collect_plugin_specs()
	local specs = {}
	for _, def in ipairs(M.get_active_definitions()) do
		if type(def.plugins) == "table" then
			for _, spec in ipairs(def.plugins) do
				table.insert(specs, vim.deepcopy(spec))
			end
		end
	end
	return specs
end

function M.register_commands()
	if vim.g._lsp_profile_commands_registered then
		return
	end

	vim.api.nvim_create_user_command("LspProfileRequirements", function()
		require("ega.custom.lsp.language_installer").show_requirements(M.get_active_definitions(), {
			profile = vim.g.NVIM_PROFILE,
		})
	end, { desc = "Show requirements for the active LSP profile" })

	vim.api.nvim_create_user_command("LspProfileInstall", function(args)
		require("ega.custom.lsp.language_installer").install_profile(M.get_active_definitions(), {
			profile = vim.g.NVIM_PROFILE,
			mason_only = args.bang,
		})
	end, {
		bang = true,
		desc = "Install tools for the active LSP profile (! = Mason only)",
	})

	vim.api.nvim_create_user_command("LspRestart", function(opts)
		local restart = require("ega.custom.lsp.restart")
		if opts.args ~= "" then
			restart.restart_attached(opts.args)
		else
			restart.restart_by_name()
		end
	end, {
		nargs = "?",
		complete = function()
			local names, seen = {}, {}
			for _, client in ipairs(vim.lsp.get_clients()) do
				if client.name and not seen[client.name] then
					seen[client.name] = true
					table.insert(names, client.name)
				end
			end
			table.sort(names)
			return names
		end,
		desc = "Restart an attached LSP client",
	})

	vim.g._lsp_profile_commands_registered = true
end

function M.setup()
	if vim.g._lsp_boot_done then
		return
	end

	vim.g._lsp_boot_done = true

	local handlers = require("ega.custom.lsp.handlers")
	if type(handlers.setup) == "function" then
		handlers.setup()
	end

	require("ega.custom.lsp.format")
	require("ega.custom.lsp.pipeline").setup_all(M.get_active_definitions())
	M.register_commands()
end

local utils = require("ega.custom.lsp.utils")
M.utils = utils

return M
