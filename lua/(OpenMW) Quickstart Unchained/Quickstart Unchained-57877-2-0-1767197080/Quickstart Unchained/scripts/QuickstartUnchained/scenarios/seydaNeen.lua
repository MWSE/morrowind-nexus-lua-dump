registerScenario({
	name = "Seyda Neen",
	order = 1,
	locationScript = function(player)
		return {
			gridX = -2,
			gridY = -9,
			position = util.vector3(-9953.0, -71768.6, 963.2),
			rotation = util.transform.rotateZ(math.rad(-47.2)),
		}
	end,
})
