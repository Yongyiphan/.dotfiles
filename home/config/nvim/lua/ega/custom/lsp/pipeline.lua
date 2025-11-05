-- lua/ega/custom/lsp/pipeline.lua
local Installer = require("ega.custom.lsp.language_installer")

local M = {}

-- discover ALL LanguageProfile modules (core + active profile), with profile override
local function discover_profiles()
  -- Safely require the name lists
  local core    = _G.call("ega.custom.lsp.settings")
  local profset = _G.call(_G.rprofile .. ".lsp.settings")

  -- If the module returns `true` (empty file) or anything non-table, ignore it
  if type(core) ~= "table" then core = nil end
  if type(profset) ~= "table" then profset = nil end

  local function as_list(x)
    return (type(x) == "table") and x or {}
  end

  local core_names = as_list(core and core.names)
  local prof_names = as_list(profset and profset.names)

  local function load(ns_root, name)
    local mod = ns_root .. ".settings." .. name
    local P = _G.call(mod)
    if type(P) == "table" then
      print("Collecting: ", mod)
      local lang = (P.meta and P.meta.lang) or name
      return { name = name, lang = lang, mod = mod, P = P }
    end
    return nil
  end

  local out, seen = {}, {}

  -- 1) profile-defined names first (override core)
  for _, name in ipairs(prof_names) do
    local item = load(_G.rprofile .. ".lsp", name)
    if item then
      out[#out + 1] = item
      seen[name] = true
    end
  end

  -- 2) any core names not provided by profile
  for _, name in ipairs(core_names) do
    if not seen[name] then
      local item = load("ega.custom.lsp", name)
      if item then out[#out + 1] = item end
    end
  end

  return out
end

local function as_list(v) return type(v)=="string" and {v} or (type(v)=="table" and v or {}) end

-- In pipeline.lua, modify start_lsp:
local function start_lsp(name, spec, caps)
  if not spec or spec.enabled == false then return end
  
  local root_markers = as_list(spec.root_dir_markers)
  local cmd = as_list(spec.cmd)
  local fts = as_list(spec.filetypes or {})
  
  local group_name = ("LSP_%s"):format(name)
  local aug = vim.api.nvim_create_augroup(group_name, { clear = true })
  
  vim.api.nvim_create_autocmd("FileType", {
    group = aug,  -- Add group
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
      
			local caps
      local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        caps = cmp_nvim_lsp.default_capabilities()
      else
        caps = vim.lsp.protocol.make_client_capabilities()
      end

      vim.lsp.start({
        name = name,
        cmd = cmd,
        root_dir = root_dir,
        settings = spec.settings,
        capabilities = caps,
      }, {
        bufnr = args.buf,
      })
    end,
  })
end

local all_none_ls_sources = {}
local none_ls_setup_done = false

local function setup_none_ls(P)
  print("Setup: none-ls for", P.meta and P.meta.lang or "unknown")
  local null_ls = _G.call("null-ls")
  if not null_ls then return end

  if not (P.hooks and type(P.hooks.none_ls_sources) == "function") then
    return
  end

  local sources = P.hooks.none_ls_sources(null_ls.builtins)
  if type(sources) ~= "table" or #sources == 0 then
    return
  end

  -- Accumulate sources from all profiles
  for _, src in ipairs(sources) do
    table.insert(all_none_ls_sources, src)
  end
end

-- Add new function to setup none-ls once with all sources:
local function finalize_none_ls()
  if #all_none_ls_sources == 0 then return end
  
  local null_ls = _G.call("null-ls")
  if not null_ls then return end

  print("Finalizing none-ls with", #all_none_ls_sources, "sources")
  
  null_ls.setup({
    sources = all_none_ls_sources,
    on_attach = function(client, bufnr)
      print("none-ls attached to buffer", bufnr)
      -- Format on save for all buffers
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({
            bufnr = bufnr,
            async = false,
            filter = function(c) return c.name == "null-ls" end,
          })
        end,
      })
    end,
  })
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
  local pats = (P.files and P.files.patterns)  or {}
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
      out[#out+1] = a
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
    local aug = vim.api.nvim_create_augroup(("Fmt_%s_cli_glob"):format((P.meta and P.meta.lang) or "lang"), { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = aug,
      pattern = pats,
      callback = function(args) attach_for_buf(args.buf) end,
    })
  end
end


-- Public: wire ALL languages declared under active profile
function M.setup_all()
  local mods = discover_profiles()
  local cmp = _G.call and _G.call("cmp_nvim_lsp")
  local caps = (cmp and cmp.default_capabilities()) or vim.lsp.protocol.make_client_capabilities()

  for _, item in ipairs(mods) do
    local P = item.P

    -- Install tools per-profile (Mason + custom)
    Installer.ensure(P, {
      use_mason = true,
      use_mason_tool_installer = true,
      mason_setup = true,              -- since you removed separate mason setup
      auto_install_with_mason = false,
      log = false,
    })

    -- Start all LSP servers
    for name, spec in pairs(P.lsp or {}) do
			spec.filetypes = spec.filetypes or P.files.filetypes
      start_lsp(name, spec, caps)
    end

    -- Formatting path (per profile)
    if P.use_none_ls then setup_none_ls(P) else setup_external_cli(P) end
  end
	Installer.finalize_mti()

	finalize_none_ls()
end

return M

