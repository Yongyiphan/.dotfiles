local local_cap = vim.lsp.protocol.make_client_capabilities()
local util = require("lspconfig.util")
local_cap.offsetEncoding = { "utf-16" }

local root_files = {
	".clangd",
	".clang-tidy",
	".clang-format",
	"compile_flags.txt",
	"compile_commands.json",
	"build.sh", -- buildProject
	"configure.ac", -- AutoTools
	"run",
	"compile",
}

_G.compile_commmands_json_to_unix = function()
	local fp = vim.loop.cwd() .. "/compile_commands.json"
	local cc_json = vim.fn.filereadable(fp)
	print(cc_json)
	if cc_json then
		local file = io.open(fp, "r")
		assert(file, "Failed to open" .. fp)
		local json_content = file:read("*a")
		file:close()
		local json = require("JSON")
		local json_table = json:decode(json_content)
		for k, v in ipairs(json_table) do
			print(k .. " " .. v)
		end
	end
end

local unused = {
	--"--cross-file-rename",
	--"--debug-origin",
	--"--fallback-style=Qt",
	--"--folding-ranges",
	--"--suggest-missing-includes",
	--"--pch-storage=memory", -- could also be disk
	--"-j=4", -- number of workers
	--"--log=error",
	--"--log=verbose",
	"--query-driver=/mnt/c/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.35.32215/bin/Hostx86/x86",
}
return {
	cmd = {
		"clangd",
		"--all-scopes-completion",
		"--background-index",
		"--clang-tidy",
		"--completion-parse=always",
		"--completion-style=bundled",
		"--enable-config", -- clangd 11+ supports reading from .clangd configuration file
		"--function-arg-placeholders",
		"--header-insertion=iwyu",
	},
	filetypes = { "c", "cpp", "objc", "objcpp", "h", "hpp", "tpp" },
}
