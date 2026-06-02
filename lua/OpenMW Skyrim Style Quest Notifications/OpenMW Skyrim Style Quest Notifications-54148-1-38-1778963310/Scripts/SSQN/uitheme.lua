local core = require("openmw.core")
local util = require("openmw.util")
local vfs = require("openmw.vfs")


local function colorCommaString(id, blend)
	local gmst = core.getGMST(id)
	if not gmst then return util.color.rgb(0.6, 0.6, 0.6) end
	local col = {}
	for v in string.gmatch(gmst, "(%d+)") do col[#col + 1] = tonumber(v) end
	if #col ~= 3 then print("Invalid RGB from "..gmst.." "..id) return util.color.rgb(0.6, 0.6, 0.6) end
	if blend then
		for i = 1, 3 do col[i] = col[i] * blend[i] end
	end
	return util.color.rgb(col[1] / 255, col[2] / 255, col[3] / 255)
end

local function findFirstFile(list)
	for _, v in ipairs(list) do
		if vfs.fileExists(v .. ".dds") then
			return v .. ".dds"
		end
		if vfs.fileExists(v .. ".png") then
			return v .. ".png"
		end
	end
end


local uiTheme = {
	normal = colorCommaString("FontColor_color_normal"),
	header = colorCommaString("FontColor_color_header"),
	background = colorCommaString("FontColor_color_background"),
	normal_over = colorCommaString("FontColor_color_normal_over"),
	normal_pressed = colorCommaString("FontColor_color_normal_pressed"),

	baseSize = 16, largeSize = 18,

	colorCommaString = colorCommaString
}

do
	local icon = uiTheme.normal
	local brightness = (icon.r + icon.g + icon.b) / 3
	if brightness < 0.585 then
		local mult = 0.585 / brightness
		icon = util.color.rgb(icon.r * mult, icon.g * mult, icon.b * mult)
	end
	uiTheme.icon = icon
	uiTheme.steal = util.color.rgb(icon.r * 1, icon.g * 0.15, icon.b * 0.15)
end


uiTheme.menuBG = findFirstFile {
	"textures/SSQN/omw_menu_background",
	"textures/omw_menu_background",
}

uiTheme.menuBG_thinWide = findFirstFile {
	"textures/SSQN/banner",
	"textures/SSQN/omw_menu_background_thin_wide",
	"textures/omw_menu_background_thin_wide",
	"textures/SSQN/omw_menu_background",
	"textures/omw_menu_background",
}


return uiTheme
