--Credits:
-- G7, Hrn, Axe, OJ, Stripes

-- TODO:

-- qwerty's ides to implement:
-- 1) Change Argonian detection ability:
--	Make the switch between land and water scent for Argonians. So, while underwater, they can detect underwater beings,
--	but not those on the land, while on the land, they can detect creatures on the land but not on the water


local common = include("q.PredatorBeastRaces.common")
dofile("q.PredatorBeastRaces.mechanics.argonianPuzzleCanal")
dofile("q.PredatorBeastRaces.mechanics.fallDamageReduction")
dofile("q.PredatorBeastRaces.mechanics.activeAbilities")
dofile("q.PredatorBeastRaces.mechanics.waterHunter")
dofile("q.PredatorBeastRaces.mechanics.clawDamage")



event.register("modConfigReady", function()
	dofile("q.PredatorBeastRaces.MCM.mcm")
	event.register("PBR_updateSettings", common.updateSettings)
end)
