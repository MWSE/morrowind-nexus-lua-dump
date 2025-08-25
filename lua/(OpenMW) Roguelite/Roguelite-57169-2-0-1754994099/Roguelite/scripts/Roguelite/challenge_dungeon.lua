local NPCFightThreshold = 90
local CreatureFightThreshold = 83
local fFightDispMult = core.getGMST("fFightDispMult")
local iFightDistanceBase =core.getGMST("iFightDistanceBase")
local fFightDistanceMultiplier = core.getGMST("fFightDistanceMultiplier")
local fightDistanceConstant = iFightDistanceBase - 500 * fFightDistanceMultiplier


local function cellCombatTargets(cell)
	local objects = cell:getAll()
	local foundLiveHostiles = 0
	local foundOriginalHostiles = 0
	
	for _, object in ipairs(objects) do
		local isNPC = types.NPC.objectIsInstance(object)
		local isCreature = types.Creature.objectIsInstance(object)
		if not isNPC and not isCreature then goto continue end
		
		local fight = object.type.stats.ai.fight(object).modified + fightDistanceConstant
		--local fightLimit = isNPC and NPCFightThreshold or CreatureFightThreshold
		local isCurrentlyHostile = fight >= 100 and not object.type.isDead(object)
		
		local objectId = object.id
		
		if saveData.originalHostileState[objectId] == nil then
			saveData.originalHostileState[objectId] = isCurrentlyHostile
		end
		
		if isCurrentlyHostile then
			foundLiveHostiles = foundLiveHostiles + 1
			print(cell.id, object.recordId)
		end
		
		if saveData.originalHostileState[objectId] then
			foundOriginalHostiles = foundOriginalHostiles + 1
		end
		
		::continue::
	end
	
	return foundLiveHostiles, foundOriginalHostiles
end
	
	
local function isExterior(cell)
	return cell.isExterior or cell:hasTag("QuasiExterior")
end

-- MAIN FUNCTION
return function(player, lastCell, currentCell)
	local lastExterior = isExterior(lastCell)
	local currentExterior = isExterior(currentCell)
	
	if currentExterior and lastExterior then
		return 
	end
	if saveData.clearedCells[lastCell.id] or saveData.clearedCells[currentCell.id] then
		return
	end
	local connectedCells = {}
	local cellCurrentEnemies = {}
	local cellOriginalEnemies = {}
	local todo
	if not currentExterior then
		todo= {[currentCell.id] = currentCell}
	else
		todo= {[lastCell.id] = lastCell}
	end
	local cellId = next(todo)
	while cellId do
		
		cell = todo[cellId]
		connectedCells[cellId] = cell
		local currentEnemies, originalEnemies = cellCombatTargets(cell)
		cellCurrentEnemies[cellId] = currentEnemies
		cellOriginalEnemies[cellId] = originalEnemies
		
		if not saveData.hostileCells[cellId] then
			saveData.hostileCells[cellId] = originalEnemies
		elseif saveData.hostileCells[cellId] < originalEnemies then
			print("originally hostile enemies increased, "..saveData.hostileCells[cellId].." -> "..originalEnemies)
			saveData.hostileCells[cellId] = originalEnemies
		end
		
		for _, door in pairs (cell:getAll(types.Door)) do
			local destCell = types.Door.destCell(door)
			if destCell and not isExterior(destCell) and not todo[destCell.id] and not connectedCells[destCell.id] then
				todo[destCell.id] = destCell
			end
		end
	
		todo[cellId] = nil
		cellId = next(todo)
	end
	local totalCells=0
	local hostileCells=0
	if currentExterior then
		print("---- exit ----")
		local enemiesBefore = 0
		local enemiesNow = 0
		
		for cellId, cell in pairs(connectedCells) do
			totalCells = totalCells+1
			if saveData.hostileCells[cellId] > 0 and not cell:hasTag("NoSleep") then
				hostileCells=hostileCells+1
			end
			
			local currentEnemies = cellCurrentEnemies[cellId]
			enemiesBefore = enemiesBefore + saveData.hostileCells[cellId]
			enemiesNow = enemiesNow + currentEnemies
		end
		
		
		if enemiesNow <= enemiesBefore/10 and hostileCells >= totalCells/2 then
			for cellId, cell in pairs(connectedCells) do
				saveData.clearedCells[cellId] = true
			end
			if enemiesBefore >= 2 then
				player:sendEvent("Roguelite_dungeonCleared")
			end
		end
		print(totalCells.." cells, "..hostileCells.." hostile, "..enemiesNow.."/"..enemiesBefore.." enemies")
	end
end