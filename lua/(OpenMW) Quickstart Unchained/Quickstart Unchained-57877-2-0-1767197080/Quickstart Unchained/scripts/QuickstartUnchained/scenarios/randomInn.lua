local findSafeSpawnPosition = require("scripts.QuickstartUnchained.QSU_findSafeSpawnPosition")

registerScenario({
	name = "Random Inn",
	description = "Wake up at a random inn across Vvardenfell.\nHow did you get here? And why is there so much liquor in your pockets?",
	locationScript = function(player)
		local validLocations = {}
		table.insert(validLocations, {
			cell = "Ald-ruhn, Ald Skar Inn",
			refNpc = "boderi farano",
			position = util.vector3(556.8, -1226.3, 1.0),
			rotation = util.transform.rotateZ(math.rad(-144.1)),
		})
		
		for _, cell in pairs(world.cells) do
			if not cell.isExterior then
				for _, npc in pairs(cell:getAll(types.NPC)) do
					local npcRecord = types.NPC.record(npc)
					local className = npcRecord.class:lower()
					if className:find("publican") then
						table.insert(validLocations, {
							cell = cell,
							refNpc = npc.recordId,
							npc = npc,
						})
						break
					end
				end
			end
		end
		
		local chosenLocation
		while #validLocations > 0 do
			local idx = math.random(1, #validLocations)
			local candidate = validLocations[idx]
			
			if candidate.npc then
				local spawnPos, faceYaw = findSafeSpawnPosition(candidate.npc, 160)
				if spawnPos then
					candidate.rotation = util.transform.rotateZ(faceYaw)
					candidate.position = spawnPos
					candidate.cell = candidate.cell.id
					chosenLocation = candidate
					break
				else
					table.remove(validLocations, idx)
				end
			else
				chosenLocation = candidate
				break
			end
		end
		return chosenLocation
	end,
	globalScripts = {
		onSelected = function(player, cell) 
			giveRandomAlcohol(player)
			giveRandomAlcohol(player)
			giveRandomAlcohol(player)
			giveRandomAlcohol(player)
			giveRandomAlcohol(player)
			giveRandomAlcohol(player)
			giveRandomAlcohol(player)
			giveFood(player)
			giveRandomArmor(player)
			if math.random() < 0.5 then
				giveLockpicks(player)
			end
		end,
	},
})
