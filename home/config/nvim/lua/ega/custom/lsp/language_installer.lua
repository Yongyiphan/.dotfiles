-- lua/ega/custom/lsp/language_installer.lua
---@class InstallerUtil
---@field exec fun(argv:string[], opts?:{cwd?:string, env?:table, silent?:boolean}): {code:integer, stdout:string, stderr:string}
---@field exec_ok fun(argv:string[], opts?:{cwd?:string, env?:table, silent?:boolean}): boolean

---@class LanguageInstallerOpts
---@field use_mason? boolean                 -- default true if mason is installed
---@field use_mason_tool_installer? boolean  -- default true if MTI is installed
---@field mason_setup? boolean               -- default true (since you removed separate mason setup)
---@field auto_install_with_mason? boolean   -- default false
---@field log? boolean                       -- default false

local M = {}

local function notify(msg, level, opts)
  if opts and opts.log then vim.notify(msg, level or vim.log.levels.INFO) end
end

local Util = {}
function Util.exec(argv, opts)
  local res = vim.system(argv, { text = true, cwd = opts and opts.cwd or nil, env = opts and opts.env or nil }):wait()
  if not (opts and opts.silent) then
    local out = (res.stdout or "") .. (res.stderr or "")
    if out ~= "" then vim.notify(out:gsub("%s+$","")) end
  end
  return res
end
function Util.exec_ok(argv, opts)
  local res = Util.exec(argv, vim.tbl_extend("force", { silent = true }, opts or {}))
  return res.code == 0
end

local function mason_has(tool_name)
	local registry = _G.call("mason-registry")
	if not registry then return false end
	local ok, pkg = pcall(registry.get_package, tool_name)
	return ok and pkg:is_installed()
end

local function exists(bin) return bin and vim.fn.executable(bin) == 1 end

local all_ensure_tools = {}

---@param P table  -- LanguageProfile
---@param opts? LanguageInstallerOpts
function M.ensure(P, opts)
  opts = opts or {}
  
  local mason = _G.call("mason")
  local mti   = _G.call("mason-tool-installer")
  
  local has_mason = mason ~= nil
  local has_mti   = mti ~= nil

  local use_mason = (opts.use_mason ~= false) and has_mason
  local use_mti   = (opts.use_mason_tool_installer ~= false) and has_mti
  local mason_setup = (opts.mason_setup ~= false)

  if use_mason and mason_setup then
    local ok = pcall(mason.setup, {})
    notify(ok and "mason.setup() ok" or "mason.setup() failed", vim.log.levels.DEBUG, opts)
  end


  -- 1) mason-tool-installer bulk ensure
if use_mason and use_mti then
    local ensure = {}
    for server, spec in pairs(P.lsp or {}) do
      if spec and spec.enabled ~= false then ensure[#ensure+1] = server end
    end
    if P.use_none_ls then
      -- Filter out tools that don't need installation
      local skip_install = { "refactoring" }  -- Add more if needed
      
      for _, n in ipairs(P.none_ls.formatting   or {}) do 
        if not vim.tbl_contains(skip_install, n) then
          ensure[#ensure+1] = n 
        end
      end
      for _, n in ipairs(P.none_ls.diagnostics  or {}) do 
        if not vim.tbl_contains(skip_install, n) then
          ensure[#ensure+1] = n 
        end
      end
      for _, n in ipairs(P.none_ls.code_actions or {}) do 
        if not vim.tbl_contains(skip_install, n) then
          ensure[#ensure+1] = n 
        end
      end
    end
    
    -- Accumulate tools
    for _, tool in ipairs(ensure) do
      if not vim.tbl_contains(all_ensure_tools, tool) then
        table.insert(all_ensure_tools, tool)
      end
    end
  end

end

function M.finalize_mti()
  local mti = _G.call("mason-tool-installer")
  if not mti or #all_ensure_tools == 0 then return end
  
  print("Final MTI ensure list:", vim.inspect(all_ensure_tools))
  mti.setup({
    ensure_installed = all_ensure_tools,
    run_on_start = true,
    auto_update = false,
    start_delay = 0,
    integrations = { ["mason-lspconfig"] = true, ["mason-null-ls"] = true },
  })
end

-- custom installer logic into separate function
function run_custom_installers(P, opts)
  local inst = P.installer
  if not (inst and inst.enabled) then return end
  
  for _, step in ipairs(inst.steps or {}) do
    local have = false
    if type(step.check_fn) == "function" then
      have = step.check_fn(Util)
    elseif step.check then
      have = exists(step.check) or mason_has(step.tool)
    end

    if not have then
      local label = step.tool or (type(step.cmd) == "function" and "<lua-fn>") or (step.run and step.run[1]) or "unknown"
      notify(("Installing %s…"):format(label), vim.log.levels.INFO, opts)
      if type(step.cmd) == "function" then
        local ok, err = pcall(step.cmd, Util)
        if not ok then vim.notify(("Installer step failed (%s): %s"):format(label, err), vim.log.levels.ERROR) end
      elseif type(step.run) == "table" then
        local res = Util.exec(step.run, { silent = not opts.log })
        if res.code ~= 0 then vim.notify(("Command failed (%s): exit %d"):format(label, res.code), vim.log.levels.ERROR) end
      end
    else
      notify(("Already present: %s"):format(step.tool or step.check or "?"), vim.log.levels.DEBUG, opts)
    end
  end
end

return M
