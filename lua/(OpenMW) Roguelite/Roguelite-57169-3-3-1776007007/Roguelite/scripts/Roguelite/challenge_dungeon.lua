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
			--print(cell.id, object.recordId)
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

local function checkCurrentDungeon(player, startCell)
	--local before = core.getRealTime()
	local currentCell = startCell or player.cell
	if isExterior(currentCell) then
		player:sendEvent("Roguelite_dungeonStatus")
		return
	end
	if saveData.clearedCells[currentCell.id] then
		player:sendEvent("Roguelite_dungeonStatus", {
			cellName = currentCell.name,
			cleared = true,
		})
		return
	end

	local connectedCells = {}
	local todo = {[currentCell.id] = currentCell}
	local enemiesBefore = 0
	local enemiesNow = 0
	local totalCells = 0
	local hostileCells = 0

	local cellId = next(todo)
	while cellId do
		local cell = todo[cellId]
		connectedCells[cellId] = cell
		local currentEnemies, originalEnemies = cellCombatTargets(cell)

		if not saveData.hostileCells[cellId] then
			saveData.hostileCells[cellId] = originalEnemies
		elseif saveData.hostileCells[cellId] < originalEnemies then
			saveData.hostileCells[cellId] = originalEnemies
		end

		enemiesNow = enemiesNow + currentEnemies
		enemiesBefore = enemiesBefore + saveData.hostileCells[cellId]
		totalCells = totalCells + 1
		if saveData.hostileCells[cellId] > 0 and not cell:hasTag("NoSleep") then
			hostileCells = hostileCells + 1
		end

		for _, door in pairs(cell:getAll(types.Door)) do
			local destCell = types.Door.destCell(door)
			if destCell and not isExterior(destCell) and not todo[destCell.id] and not connectedCells[destCell.id] then
				todo[destCell.id] = destCell
			end
		end

		todo[cellId] = nil
		cellId = next(todo)
	end

	local qualifies = hostileCells >= totalCells / 2 and enemiesBefore >= 2

	player:sendEvent("Roguelite_dungeonStatus", {
		cellName = currentCell.name,
		enemiesKilled = enemiesBefore - enemiesNow,
		enemiesTotal = enemiesBefore,
		cleared = false,
		qualifies = qualifies,
	})

	if enemiesNow <= enemiesBefore / 10 and qualifies then
		for cId, cell in pairs(connectedCells) do
			saveData.clearedCells[cId] = true
		end
		player:sendEvent("Roguelite_dungeonCleared")
		player:sendEvent("Roguelite_dungeonStatus", {
			cellName = currentCell.name,
			cleared = true,
		})
	end
	--print("etime", (core.getRealTime()-before)*1000)
end

local function onCellChange(player, lastCell, currentCell)
    local lastExterior = isExterior(lastCell)
    local currentExterior = isExterior(currentCell)

    if currentExterior and lastExterior then return end
    if saveData.clearedCells[lastCell.id] or saveData.clearedCells[currentCell.id] then return end

    -- If exiting to exterior, check the dungeon we just left
    if currentExterior then
        checkCurrentDungeon(player, lastCell)
    end
	if not currentExterior then
		checkCurrentDungeon(player)
	end
end

return {
	onCellChange = onCellChange,
	checkCurrentDungeon = checkCurrentDungeon,
}