registerScenario({
	name = "Balmora",
	order = 2,
	locationScript = function(player)
		return {
			gridX = -2,
			gridY = -2,
			position = util.vector3(-14820.7, -13332.2, 962.8),
			rotation = util.transform.rotateZ(math.rad(270)),
		}
	end,
	globalScripts = {
		onSelected = function(player, cell) getRandomItems(player) end,
	},
})
