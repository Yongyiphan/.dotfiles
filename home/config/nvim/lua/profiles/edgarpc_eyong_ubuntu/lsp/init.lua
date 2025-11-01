local M = {}
local settings = {}
do
	local names = {
		"c_cpp",
		"python",
		"cmake",
	}
	for _, name in ipairs(names) do
		local mod = _G.call(_G.rprofile .. ".lsp.settings." .. name)
		if mod then table.insert(settings, mod) end
	end
end

M.settings = settings

return M
