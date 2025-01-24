local lualine_nightfly = require("lualine.themes.nightfly")


local ncolor = {
	blue = "#65D1FF",
	green = "#3EFFDC",
	violet = "#B356FF",
	yellow = "#FFDA7B",
	black = "#000000",
}

lualine_nightfly.normal.a.bg = ncolor.blue
lualine_nightfly.insert.a.bg = ncolor.green
lualine_nightfly.visual.a.bg = ncolor.violet
lualine_nightfly.command = {
	a = {
		gui = "bold",
		bg = ncolor.yellow,
		fg = ncolor.black,
	},
}


require("lualine").setup({
	options = {
		theme = lualine_nightfly,
	},
})
