--- Initialzing
local function onInit()
	event.register("loaded", function()
		local metadata = toml.loadMetadata("Furniture Catalogue")
		if not metadata then
			tes3.messageBox("[Furniture Catalogue: ERROR] Missing metadata")
			return
		end
		local version = metadata.package.version
		tes3.player.data.furnitureCatalogue = tes3.player.data.furnitureCatalogue or {}
		tes3.player.data.furnitureCatalogue.version = version
	end)
	require("JosephMcKean.furnitureCatalogue.interop")
	require("JosephMcKean.furnitureCatalogue.catalogue")
	require("JosephMcKean.furnitureCatalogue.recipes")
end
event.register("initialized", onInit)

-- to make sure to get the interop furniture indices
event.register("initialized", function() require("JosephMcKean.furnitureCatalogue.furnConfig").getValidFurniture() end, { priority = -10 })

require("JosephMcKean.furnitureCatalogue.mcm")
