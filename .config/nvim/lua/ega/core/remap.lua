local MapGroup = _G.Core.MapGroup
local vmap = vim.keymap.set
local telescope = _G.call("telescope")
if not telescope then
	return
end
local whichkey = _G.call("which-key")
if not whichkey then
	return
end

local sections = {
	f = { group = "Find" },
	c = { group = "Config" },
	i = { group = "Info" },
	e = { group = "Explorer" },
	b = { group = "Buffers" },
	p = { group = "Project" },
	g = { group = "Git" },
	s = { group = "Split" },
	h = { group = "Help" },
	d = { group = "Debug" },
	u = { group = "UI" },
	l = { group = "LSP" },
}

-- Initial Load of all Custom configs
local Custom = require("ega.custom")
local Utils = require("ega.core.utils")

vmap("n", "Q", "<nop>", KeyOpts())
vmap("v", "J", ":m '>+1<CR>gv=gv", KeyOpts())
vmap("v", "K", ":m '<-2<CR>gv=gv", KeyOpts())
vmap("v", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>", KeyOpts("Rename"))

vmap("x", "<leader>p", '"_dP', KeyOpts("Paste & Keep"))
vmap("n", "<leader>w", [[:w<CR>]], KeyOpts("W"))
vmap("n", "<leader>q", [[:q<CR>]], KeyOpts("Q"))
vmap("n", "<leader>y", "ggVGy<C-o>", KeyOpts("Yank Yall"))
vmap("n", "<leader>x", "ggVGy<C-o>", KeyOpts("WQ"))

--
--Splits (Default = <C-w>)
--
MapGroup["<leader>s"] = sections.s
vmap("n", "<leader>sv", "<C-w>v", KeyOpts("Split vert"))
vmap("n", "<leader>sh", "<C-w>s", KeyOpts("Split hort"))
vmap("n", "<leader>se", "<C-w>=", KeyOpts("Equal split size"))
vmap("n", "<leader>sx", ":close<CR>", KeyOpts("Close curr split"))
vmap("n", "<leader>sj", "<C-w>j", KeyOpts("Move to Above Split"))
vmap("n", "<leader>sk", "<C-w>k", KeyOpts("Move to Below Split"))
vmap("n", "<leader>sh", "<C-w>h", KeyOpts("Move to Left  Split"))
vmap("n", "<leader>sl", "<C-w>l", KeyOpts("Move to Right Split"))
vmap('n', '<Leader>si', '<cmd>lua adjust_width("+5")<CR>', KeyOpts("Increase Width"))
vmap('n', '<Leader>sd', '<cmd>lua adjust_width("-5")<CR>', KeyOpts("Decrease Width"))

--Diagnostics
MapGroup["<leader>i"] = sections.i
vmap("n", "<leader>ia", "<cmd>Telescope diagnostics<CR>", KeyOpts("Diagnostics"))
vmap("n", "<leader>i[", "<cmd>lua vim.diagnostic.goto_prev()<CR>", KeyOpts("Prev Error"))
vmap("n", "<leader>i]", "<cmd>lua vim.diagnostic.goto_next()<CR>", KeyOpts("Next Error"))
vmap("n", "<leader>ic", Custom.diagnostics.close_diag_at_cursor, KeyOpts("At Cursor"))
vmap("n", "<leader>il", Custom.diagnostics.close_diag_at_line, KeyOpts("At Line"))
vmap("n", "<leader>im", "<cmd>messages<CR>", KeyOpts("Sys Messages"))

MapGroup["<leader>l"] = sections.l
vmap("n", "<leader>ll", "<cmd>LspLog<CR>", KeyOpts("LSP Log"))
vmap("n", "<leader>li", "<cmd>LspInfo<CR>", KeyOpts("Lsp Info"))
vmap("n", "<leader>lr", "<cmd>LspRestart<CR>", KeyOpts("Lsp Restart"))

--
--Config
--
MapGroup["<leader>c"] = sections.c
vmap("n", "<leader>cf", Custom.config.t_core_files, KeyOpts("Telescope Config"))
vmap("n", "<leader>cs", Custom.config.t_share_files, KeyOpts("Telescope Share Files"))
vmap("n", "<leader>ce", Custom.config.b_core_files, KeyOpts("Browse Core Files"))
vmap("n", "<leader>cE", Custom.config.b_share_files, KeyOpts("Browse Share Files"))
--
--Find
--
MapGroup["<leader>f"] = sections.f
vmap("n", "<leader>fm", Custom.fzflua.main_fzf_files, KeyOpts("From C:"))
vmap("n", "<leader>ff", Custom.telescope.find_files_custom, KeyOpts("Project File"))
vmap("n", "<leader>fw", Custom.telescope.live_grep_files, KeyOpts("Word"))
vmap("n", "<leader>fo", Custom.telescope.builtin.oldfiles, KeyOpts("Old Files"))
vmap("n", "<leader>fg", Custom.git.G_git_files, KeyOpts("Git Files"))
vmap("n", "<leader>fl", Utils.CurrentLoc, KeyOpts("File Loc"))

--
--Git Stuffs
--
MapGroup["<leader>g"] = sections.g
vmap("n", "<leader>gt", Custom.git._lazygit_toggle, KeyOpts("Git Terminal"))

--
--File Explorer Stuffs
--
--MapGroup["<leader>e"] = sections.e
vmap("n", "<leader>e", Custom.telescope.open_file_explorer, KeyOpts(sections.e.name))

-- Default keymaps in insert/normal mode:
-- `<cr>`: opens the currently selected file, or navigates to the currently selected directory
-- `<A-c>/c`: Create file/folder at current `path` (trailing path separator creates folder)
-- `<A-r>/r`: Rename multi-selected files/folders
-- `<A-m>/m`: Move multi-selected files/folders to current `path`
-- `<A-y>/y`: Copy (multi-)selected files/folders to current `path`
-- `<A-d>/d`: Delete (multi-)selected files/folders
-- `<C-o>/o`: Open file/folder with default system application
-- `<C-g>/g`: Go to parent directory
-- `<C-e>/e`: Go to home directory
-- `<C-w>/w`: Go to current working directory (cwd)
-- `<C-t>/t`: Change nvim's cwd to selected folder/file(parent)
-- `<C-f>/f`: Toggle between file and folder browser
-- `<C-h>/h`: Toggle hidden files/folders
-- `<C-s>/s`: Toggle all entries ignoring `./` and `../`
-- ` <bs>/` : Goes to parent dir if prompt is empty, otherwise acts normally
-- '   <>/]': Ignore .gitignore

--
--Buffer
--
MapGroup["<leader>b"] = sections.b
vmap("n", "<leader>bx", "<cmd>:BDelete this<CR>", KeyOpts("Clear this  buf"))
vmap("n", "<leader>bX", "<cmd>:BDelete! this<CR>", KeyOpts("Clear this  buf"))
vmap("n", "<leader>bo", "<cmd>:BWipeout other<CR>", KeyOpts("Clear other buf"))
vmap("n", "<leader>ba", "<cmd>:BWipeout all<CR>", KeyOpts("Clear *ALL* buf"))
vmap("n", "<leader>bA", "<cmd>:BWipeout! all<CR>", KeyOpts("Clear *ALL* buf"))
vmap("n", "<leader>bb", Custom.telescope.builtin.buffers, KeyOpts("List Buffers"))
vmap("n", "<leader>bl", Utils.CurrentLoc, KeyOpts("Filepath"))

vmap("n", "<tab>", "<cmd>:BufferLineCycleNext<CR>", KeyOpts("Next buffer"))
vmap("n", "<S-tab>", "<cmd>:BufferLineCyclePrev<CR>", KeyOpts("Prev buffer"))

--
--Help
--
MapGroup["<leader>h"] = sections.h
vmap("n", "<leader>hc", Custom.cs.cheatsheet_toggle, KeyOpts("Cheat Sheet"))
vmap("n", "<leader>hk", Custom.telescope.builtin.keymaps, KeyOpts("Key Maps"))

--
--Debug
--
local dap = _G.call("dap")
if not dap then
	return
end
MapGroup["<leader>d"] = sections.d
MapGroup["<leader>du"] = sections.u
require("ega.custom.dap.keybinding")
--
--Register Key Groups
--

local function reformat_keybindingStruture(map)
	local list = {}
	for key, value in pairs(map) do
		table.insert(list, { key, value.group })
	end
	return list
end

whichkey.add(reformat_keybindingStruture(MapGroup))
-- whichkey.register(MapGroup)
