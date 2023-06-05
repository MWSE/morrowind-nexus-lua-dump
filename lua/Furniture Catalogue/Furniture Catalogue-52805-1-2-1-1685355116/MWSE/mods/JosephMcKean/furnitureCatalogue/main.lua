--- Initialzing
local function onInit()
	event.register("loaded", function()
		tes3.player.data.furnitureCatalogue = tes3.player.data.furnitureCatalogue or {}
	end)
	require("JosephMcKean.furnitureCatalogue.interop")
	require("JosephMcKean.furnitureCatalogue.catalogue")
	require("JosephMcKean.furnitureCatalogue.recipes")
end
event.register("initialized", onInit)

-- to make sure to get the interop furniture indices
event.register("initialized", require("JosephMcKean.furnitureCatalogue.furnConfig").getFurnitureIndices, { priority = -10 })

require("JosephMcKean.furnitureCatalogue.mcm")
