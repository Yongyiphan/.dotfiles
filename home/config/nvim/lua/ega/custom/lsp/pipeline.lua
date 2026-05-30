local M = {}

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
	if #cmd == 0 or vim.fn.executable(cmd[1]) ~= 1 then
		return
	end
	
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

			local ctx = {
				bufnr = args.buf,
				bufname = bufname,
				root_dir = root_dir,
			}

			if type(spec.condition) == "function" and not spec.condition(ctx) then
				return
			end

			local settings = spec.settings
			if type(settings) == "function" then
				settings = settings(ctx)
			end
			
			vim.lsp.start({
				name = name,
				cmd = cmd,
				root_dir = root_dir,
				settings = settings,
				capabilities = caps,
			}, { bufnr = args.buf })
		end,
	})
end

-- ============================================================================
-- none-ls Integration
-- The project moved to `nvimtools/none-ls.nvim`, but the runtime API
-- intentionally remains `require("null-ls")`.
-- ============================================================================

local function setup_none_ls(P, sources_accumulator)
	local editor = P.editor or {}
	if type(editor.none_ls_sources) ~= "function" then
		return
	end
	
	local null_ls = _G.call("null-ls")
	if not null_ls or not null_ls.builtins then
		return
	end
	
	local sources = editor.none_ls_sources(null_ls.builtins)
	if type(sources) ~= "table" or #sources == 0 then return end
	
	-- Register with filetype filtering
	local filetypes = P.meta and P.meta.filetypes or {}
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
	
	if vim.g._ega_none_ls_setup_done then
		return
	end

	local skip_format_for_ft = {}
	for _, def in pairs(M._loaded_defs or {}) do
		local filetypes = def.meta and def.meta.filetypes or {}
		local format_on_save = ((def.editor or {}).format_on_save) or {}
		if format_on_save.enabled == false then
			for _, ft in ipairs(filetypes) do
				skip_format_for_ft[ft] = true
			end
		end
	end
	
	null_ls.setup({
		sources = sources,
		on_attach = function(client, bufnr)
			if not client.supports_method("textDocument/formatting") then return end
			
			local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
			
			if skip_format_for_ft[ft] then
				return
			end
			
			pcall(vim.api.nvim_clear_autocmds, { group = "EgaFormatOnSaveLocal", buffer = bufnr })
			vim.b[bufnr].ega_local_format = true
			
			-- Only create autocmd if enabled
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("EgaFormatOnSaveLocal", { clear = false }),
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({
						bufnr = bufnr,
						async = false,
						timeout_ms = 3000,
						filter = function(fmt_client)
							return fmt_client.id == client.id
						end,
					})
				end,
			})
		end,
	})
	
	vim.g._ega_none_ls_setup_done = true
end

-- ============================================================================
-- Main Setup
-- ============================================================================
function M.setup_all(definitions)
	if type(definitions) ~= "table" or #definitions == 0 then
		vim.notify("[LSP] No languages enabled", vim.log.levels.ERROR)
		return
	end
	
	M._loaded_defs = {}
	for _, def in ipairs(definitions) do
		if type(def) == "table" and type(def.meta) == "table" and type(def.lsp) == "table" then
			M._loaded_defs[def.meta.name or tostring(#M._loaded_defs + 1)] = def
		end
	end
	
	local all_none_ls_sources = {}
	local cmp = _G.call("cmp_nvim_lsp")
	local caps = (cmp and cmp.default_capabilities()) or vim.lsp.protocol.make_client_capabilities()
	
	for _, def in pairs(M._loaded_defs) do
		for name, spec in pairs(def.lsp or {}) do
			spec.filetypes = spec.filetypes or (def.meta and def.meta.filetypes)
			start_lsp(name, spec, caps)
		end
		
		setup_none_ls(def, all_none_ls_sources)
	end
	
	finalize_none_ls(all_none_ls_sources)
end

return M
