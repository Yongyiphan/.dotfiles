-- lua/ega/custom/lsp/pipeline.lua
local Installer = require("ega.custom.lsp.language_installer")

local M = {}

-- ============================================================================
-- Language Discovery & Loading
-- ============================================================================

---@return string[] List of enabled languages (with default profile fallback)
local function discover_enabled_languages()
	-- Try current profile first
	local profile_lsp_mod = string.format("%s.lsp", _G.rprofile)
	local mod = _G.call(profile_lsp_mod)
	
	if mod and type(mod.languages) == "table" and #mod.languages > 0 then
		print(string.format("[LSP] ✅ Using languages from profile '%s'", _G.rprofile))
		return mod.languages
	end
	
	-- Fall back to default profile
	local default_mod = _G.call("profiles.default.lsp")
	if default_mod and type(default_mod.languages) == "table" then
		vim.notify(string.format("[LSP] Profile '%s' has no languages, using defaults", _G.rprofile), vim.log.levels.INFO)
		return default_mod.languages
	end
	
	-- Last resort
	vim.notify("[LSP] No languages defined anywhere, using fallback", vim.log.levels.WARN)
	return { "lua" }
end

---@param lang string Language name
---@return table|nil FullProfile with .plugins and .settings
local function load_language_definition(lang)
	local def_mod = string.format("lsp.%s", lang)
	local def = _G.call(def_mod)
	
	if not def or not def.settings then
		print(string.format("[LSP] ❌ Invalid definition for '%s' at lsp/%s.lua", lang, lang))
		return nil
	end
	
	return def
end

-- ============================================================================
-- LSP Server Management
-- ============================================================================

local function as_list(v)
	return type(v) == "string" and { v } or (type(v) == "table" and v or {})
end

local function start_lsp(name, spec, caps)
	if not spec or spec.enabled == false then return end
	
	local root_markers = as_list(spec.root_dir_markers or {})
	local cmd = as_list(spec.cmd)
	local fts = as_list(spec.filetypes or {})
	
	if #fts == 0 then return end
	
	local group_name = "LSP_" .. name
	local aug = vim.api.nvim_create_augroup(group_name, { clear = true })
	
	vim.api.nvim_create_autocmd("FileType", {
		group = aug,
		pattern = fts,
		callback = function(args)
			local clients = vim.lsp.get_clients({ bufnr = args.buf, name = name })
			if #clients > 0 then return end
			
			local bufname = vim.api.nvim_buf_get_name(args.buf)
			local root_dir = vim.fs.root(bufname, root_markers)
			
			if not root_dir then
				if spec.single_file_support ~= false then
					root_dir = vim.fn.fnamemodify(bufname, ":h")
				else
					return
				end
			end
			
			vim.lsp.start({
				name = name,
				cmd = cmd,
				root_dir = root_dir,
				settings = spec.settings,
				capabilities = caps,
			}, { bufnr = args.buf })
		end,
	})
end

-- ============================================================================
-- null-ls Integration
-- ============================================================================

local function setup_none_ls(P, sources_accumulator)
	if not P.hooks or type(P.hooks.none_ls_sources) ~= "function" then
		return
	end
	
	local sources = P.hooks.none_ls_sources(require("null-ls").builtins)
	if type(sources) ~= "table" or #sources == 0 then return end
	
	-- Register with filetype filtering
	local filetypes = P.files and P.files.filetypes or {}
	for _, src in ipairs(sources) do
		table.insert(sources_accumulator, src.with({
			filetypes = #filetypes > 0 and filetypes or nil,
		}))
	end
end

local function finalize_none_ls(sources)
	if #sources == 0 then return end
	
	local null_ls = _G.call("null-ls")
	if not null_ls then return end
	
	if vim.g._null_ls_setup_done then
		print("[LSP] null-ls already fully configured")
		return
	end
	
	print(string.format("[LSP] Finalizing none-ls with %d sources", #sources))
	
	-- Build skip list for auto-format
	local skip_format_for_ft = {}
	for _, def in pairs(M._loaded_defs or {}) do
		local P = def.settings
		if P.format_on_save and P.format_on_save.enable == false then
			for _, ft in ipairs(P.files and P.files.filetypes or {}) do
				skip_format_for_ft[ft] = true
			end
		end
	end
	
	null_ls.setup({
		sources = sources,
		on_attach = function(client, bufnr)
			if not client.supports_method("textDocument/formatting") then return end
			
			local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
			
			-- Skip auto-format if disabled for this filetype
			if skip_format_for_ft[ft] then
				return
			end
			
			-- Only create autocmd if enabled
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("EgaFormatOnSave", { clear = false }),
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr, async = false, timeout_ms = 3000 })
				end,
			})
		end,
	})
	
	vim.g._null_ls_setup_done = true
end

-- STRICT: only run if profile declares steps (or a dynamic steps hook)
local function setup_external_cli(P)
	local fmt = P.format_on_save or {}
	if not fmt.enable then return end
	
	local has_dyn = P.hooks and type(P.hooks.external_cli_steps) == "function"
	local has_static = type(fmt.steps) == "table" and #fmt.steps > 0
	if not has_dyn and not has_static then
		return -- nothing declared -> skip
	end
	
	local fts  = (P.files and P.files.filetypes) or {}
	local pats = (P.files and P.files.patterns) or {}
	if (#fts == 0) and (#pats == 0) then
		return -- no scope declared -> skip
	end
	
	local function expand_args(argv, ctx)
		local out = {}
		for _, a in ipairs(argv or {}) do
			if type(a) == "string" then
				a = a
						:gsub("{file}", ctx.filename)
						:gsub("{bufnr}", tostring(ctx.bufnr))
						:gsub("{line_length}", tostring((fmt.vars and fmt.vars.line_length) or ""))
			end
			out[#out + 1] = a
		end
		return out
	end
	
	local function attach_for_buf(bufnr)
		local aug = vim.api.nvim_create_augroup(("Fmt_%s_cli"):format((P.meta and P.meta.lang) or "lang"), { clear = false })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = aug,
			buffer = bufnr,
			callback = function(args)
				local ctx = {
					bufnr = args.buf,
					filename = vim.api.nvim_buf_get_name(args.buf),
					vars = fmt.vars or {},
					profile = P,
				}
				
				local steps = has_dyn and (P.hooks.external_cli_steps(ctx) or {}) or fmt.steps
				if type(steps) ~= "table" or #steps == 0 then return end
				
				for _, step in ipairs(steps) do
					if step.when and type(step.when) == "function" then
						local ok_keep, keep = pcall(step.when, ctx)
						if not ok_keep or not keep then goto continue end
					end
					if type(step.fn) == "function" then
						pcall(step.fn, ctx)
					elseif type(step.run) == "table" then
						local argv = expand_args(step.run, ctx)
						local opts = { text = true }
						if step.cwd then opts.cwd = step.cwd end
						if step.env then opts.env = step.env end
						local res = vim.system(argv, opts):wait(step.timeout and tonumber(step.timeout) or nil)
						if res.code ~= 0 then
							vim.notify(("cmd failed (%s) exit %d\n%s%s"):format(
								table.concat(argv, " "), res.code, res.stdout or "", res.stderr or ""
							), vim.log.levels.ERROR)
						end
					end
					::continue::
				end
			end,
		})
	end
	
	if #fts > 0 then
		vim.api.nvim_create_autocmd("FileType", {
			pattern = fts,
			callback = function(ev) attach_for_buf(ev.buf) end,
		})
	else
		-- pattern fallback only if explicitly declared by profile
		local aug = vim.api.nvim_create_augroup(("Fmt_%s_cli_glob"):format((P.meta and P.meta.lang) or "lang"),
			{ clear = true })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = aug,
			pattern = pats,
			callback = function(args) attach_for_buf(args.buf) end,
		})
	end
end


-- ============================================================================
-- Main Setup
-- ============================================================================
function M.setup_all()
	local enabled_langs = discover_enabled_languages()
	if #enabled_langs == 0 then
		vim.notify("[LSP] No languages enabled", vim.log.levels.ERROR)
		return
	end
	
	-- Load all definitions first
	M._loaded_defs = {}
	for _, lang in ipairs(enabled_langs) do
		local def = load_language_definition(lang)
		if def then
			M._loaded_defs[lang] = def
		end
	end
	
	-- Setup each language
	local all_none_ls_sources = {}
	local cmp = _G.call("cmp_nvim_lsp")
	local caps = (cmp and cmp.default_capabilities()) or vim.lsp.protocol.make_client_capabilities()
	
	for _, def in pairs(M._loaded_defs) do
		local P = def.settings
		
		-- Install tools
		Installer.ensure(P, {
			use_mason = true,
			use_mason_tool_installer = true,
			mason_setup = true,
			auto_install_with_mason = false,
			log = false,
		})
		
		-- Start LSP servers
		for name, spec in pairs(P.lsp or {}) do
			spec.filetypes = spec.filetypes or (P.files and P.files.filetypes)
			start_lsp(name, spec, caps)
		end
		
		-- Setup formatting
		if P.use_none_ls then
			setup_none_ls(P, all_none_ls_sources)
		else
			setup_external_cli(P)
		end
	end
	
	Installer.finalize_mti()
	finalize_none_ls(all_none_ls_sources)
end

return M
