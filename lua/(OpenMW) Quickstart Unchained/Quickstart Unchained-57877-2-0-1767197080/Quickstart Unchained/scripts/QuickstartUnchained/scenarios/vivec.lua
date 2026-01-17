registerScenario({
	name = "Vivec - Foreign Quarter",
	order = 3,
	locationScript = function(player)
		return {
			gridX = 6,
			gridY = -12,
			position = util.vector3(27402.5, -77000.7, 666.2),
			rotation = util.transform.rotateZ(math.rad(179.4)),
		}
	end,
	globalScripts = {
		onSelected = function(player, cell) getRandomItems(player) end,
	},
})
