if tes3.isModActive("reflections in water.esp") then
	event.register("loaded", function()
		tes3.player.data.reflectionsInWater = tes3.player.data.reflectionsInWater or {}
	end)
	require("JosephMcKean.reflectionsInWater.sitting")
	require("JosephMcKean.reflectionsInWater.pacify")
	require("JosephMcKean.reflectionsInWater.dyingFish")
	require("JosephMcKean.reflectionsInWater.corpse")
	require("JosephMcKean.reflectionsInWater.achievement")
end
