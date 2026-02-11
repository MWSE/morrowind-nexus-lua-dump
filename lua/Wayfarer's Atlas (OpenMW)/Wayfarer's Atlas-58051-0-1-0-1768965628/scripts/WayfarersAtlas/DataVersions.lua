local Immutable = require("scripts/WayfarersAtlas/Immutable")
local Dictionary = Immutable.Dictionary

return {
	saveData = {},
	multisaveData = {
		[1] = function(data)
			return Dictionary.mergeDeep(data, {
				UISaveData = {
					windowPositions = { mapWindowDefault = data.windowOffset },
					windowSizes = { mapWindowDefault = data.windowSize },
				},
			})
		end,
	},
}
