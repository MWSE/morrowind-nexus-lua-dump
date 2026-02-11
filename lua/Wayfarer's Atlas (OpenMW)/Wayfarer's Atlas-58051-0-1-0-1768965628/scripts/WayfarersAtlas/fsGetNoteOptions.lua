local VFS = require("openmw.vfs")

local Utils = require("scripts/WayfarersAtlas/Utils")
local Immutable = require("scripts/WayfarersAtlas/Immutable")
local Array = Immutable.Array

local FileUtils = require("scripts/WayfarersAtlas/FileUtils")

local ICON_DIRS = {
	"icons/WayfarersAtlas/map-icons/",
	"icons/WayfarersAtlas/uesp-icons/",
}

--[[search&replace:
(.+)=(.+)
-- rgb($2)\nUtils.colorFromGMST("fontcolor_$1"),
-- $1\nUtils.rgb($2),
]]
local colors = {
	-- color_normal
	Utils.rgb(202, 165, 96),
	-- color_disabled_over
	Utils.rgb(223, 201, 159),
	-- color_normal_over
	Utils.rgb(243, 237, 221),
	-- color_big_answer_pressed
	Utils.rgb(243, 237, 22),
	-- color_journal_link
	-- Utils.rgb(37, 49, 112),
	-- color_journal_topic_over
	Utils.rgb(58, 77, 175),
	-- color_active
	Utils.rgb(96, 112, 202),
	-- color_big_link
	Utils.rgb(112, 126, 207),
	-- color_big_link_pressed
	Utils.rgb(175, 184, 228),
	-- color_active_pressed
	Utils.rgb(223, 226, 244),

	-- color_background
	-- Utils.rgb(0, 0, 0),
	-- color_focus
	Utils.rgb(80, 80, 80),

	-- color_big_answer
	Utils.rgb(150, 50, 30),
	-- color_health
	Utils.rgb(200, 60, 30),
	-- color_fatigue
	Utils.rgb(0, 150, 60),
	-- color_misc
	Utils.rgb(0, 205, 205),
}

local function fsGetNoteOptions()
	local icons = {}

	for _, iconDir in ipairs(ICON_DIRS) do
		for iconPath in VFS.pathsWithPrefix(iconDir) do
			if iconPath:lower():match("%.dds$") then
				table.insert(icons, iconPath)
			end
		end
	end

	table.sort(icons, function(a, b)
		return FileUtils.fileName(a) < FileUtils.fileName(b)
	end)

	local circleIndex = Array.find(icons, function(icon)
		return icon:lower():find("circle.dds$") ~= nil
	end)

	if circleIndex then
		local icon = table.remove(icons, circleIndex)
		table.insert(icons, 1, icon)
	end

	return {
		icons = icons,
		colors = colors,
	}
end

return fsGetNoteOptions
