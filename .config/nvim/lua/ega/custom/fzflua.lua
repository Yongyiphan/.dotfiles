local fzf_lua = _G.call("fzf-lua")
if not fzf_lua then
	return
end
local M = {}
--Searches MNT/C
M.main_fzf_files = function()
	fzf_lua.files({
		cwd = _G.Main_Dir,
		git_icons = true,
		file_icons = true,
		color_icons = true,
		fd_opts = "-H -t f -L --ignore-file $HOME/.config/nvim/ignore/.fdignore_main",
	})
end

M.live_grep = function(opts)
	opts = opts or {}
	opts.prompt = "rg> "
	opts.git_icons = true
	opts.file_icons = true
	opts.color_icons = true
	-- setup default actions for edit, quickfix, etc
	opts.actions = fzf_lua.defaults.actions.files
	-- see preview overview for more info on previewers
	opts.previewer = "builtin"
	opts.fn_transform = function(x)
		return fzf_lua.make_entry.file(x, opts)
	end
	-- we only need 'fn_preprocess' in order to display 'git_icons'
	-- it runs once before the actual command to get modified files
	-- 'make_entry.file' uses 'opts.diff_files' to detect modified files
	-- will probaly make this more straight forward in the future
	opts.fn_preprocess = function(o)
		opts.diff_files = fzf_lua.make_entry.preprocess(o).diff_files
		return opts
	end
	return fzf_lua.fzf_live(function(q)
		return "rg --column --color=always -- " .. vim.fn.shellescape(q or "")
	end, opts)
end

-- We can use our new function on any folder or
-- with any other fzf-lua options ('winopts', etc)
--_G.live_grep({ cwd = "<my folder>" })

fzf_lua.setup({
	files = {
		fd_opts = "-HI --color=always --type f  --follow --ignore-file ~/.config/nvim/ignore/.general_ignore",
	},
})
return M
