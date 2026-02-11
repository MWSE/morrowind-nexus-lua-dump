local OMWUtil = require("openmw.util")

return {
	---@type string[]
	noteIconPaths = {},
	noteColors = {},
	getScreenSpace = function()
		return OMWUtil.vector2(0.1, 0.1)
	end,
	saveData = {
		---@type table<string, string>
		windowPositions = {},
		---@type table<string, string>
		windowSizes = {},
	},
}
