if core.contentFiles.has('TR_Mainland.esm') then
	registerScenario({
		name = "Old Ebonheart",
		order = 4,
		locationScript = function(player)
			return {
				gridX = 7,
				gridY = -18,
				position = util.vector3(60965.3, -145551.9, 340.2),
				rotation = util.transform.rotateZ(math.rad(178.8)),
			}
		end,
		globalScripts = {
			onSelected = function(player, cell) getRandomItems(player) end,
		},
	})
end
