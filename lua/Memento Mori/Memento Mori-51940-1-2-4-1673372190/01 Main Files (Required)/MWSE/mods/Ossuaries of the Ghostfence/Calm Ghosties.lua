local log = require("logging.logger").new({ name = "Ossuaries of the Ghostfence", logLevel = "INFO" })
local catacombsCells = {
	["Ghostfence, Eastern Catacombs"] = true,
	["Ghostfence, Southern Catacombs"] = true,
	["Ghostfence, Western Catacombs"] = true,
	["Ghostgate, Hall of Ghosts"] = true,
	["Ossuary of Ayem, Bone Pit"] = true,
	["Ossuary of Seht"] = true,
	["Ossuary of Vehk, Hall of the Order"] = true,
}
local isGhosty = { ["ancestor_ghost"] = true, ["ancestor_ghost_greater"] = true, ["ancestor_ghost_summon"] = true }
local isCatacombsCreature = {
	["ancestor_ghost"] = true,
	["bonewalker"] = true,
	["skeleton"] = true,
	["skeleton archer"] = true,
	["BM_wolf_skeleton"] = true,
	["skeleton warrior"] = true,
	["Bonewalker_Greater"] = true,
	["bonelord"] = true,
	["skeleton champion"] = true,
	["skeleton nord "] = true,
	["skeleton nord_2"] = true,
	["ancestor_ghost_greater"] = true,
	["bm skeleton champion gr"] = true,
	["lich"] = true,
	["GG_A_highbonelord"] = true,
	["GG_A_Bonewalker_Greater"] = true,
	["GG_A_Skeletal_Golem"] = true,
	["GG_A_bone_crab"] = true,
	["GG_A_skeletal_spider"] = true,
	["GG_S_BW_Centurion"] = true,
	["GG_S_BW_sphere"] = true,
	["GG_S_skull_centurion"] = true,
	["GG_V_skull_durzog"] = true,
	["GG_V_skullscrib"] = true,
	["GG_V_nix-hound"] = true,
	["GG_V_skelk"] = true,
}
local calmLevel = {
	["GG_Order_of_Ghosts_Boots"] = 1.49,
	["GG_Order_of_Ghosts_Bracer_L"] = 0.55875,
	["GG_Order_of_Ghosts_Bracer_R"] = 0.55875,
	["GG_Order_of_Ghosts_Cuirass"] = 3.3525,
	["GG_Order_of_Ghosts_greaves"] = 2.6075,
	["GG_Order_of_Ghosts_Hood"] = 0.745,
	["GG_Order_of_Ghosts_Pauld_L"] = 0.894,
	["GG_Order_of_Ghosts_Pauld_R"] = 0.894,
}
local isCatacombsRunner = {
	["GG_defender_01"] = true,
	["GG_defender_02"] = true,
	-- ["GG_elik_daril"] = true,
	["GG_guardian_01"] = true,
	["GG_runner_01"] = true,
	["GG_runner_02"] = true,
	["GG_runner_03_stationed"] = true,
	["GG_scout_01"] = true,
	["GG_sergeant_01"] = true,
	["GG_sergeant_02"] = true,
	["GG_sergeant_03"] = true,
}

local shallNotPassDoor = "GG_catacombs_door"

---comment
---@param creaPosition tes3vector3
--- @return number minDistance
--- @return tes3reference minDoorRef
local function getDistanceOfClosestDoor(creaPosition)
	local minDistance = math.huge
	local minDoorRef
	for doorRef in tes3.player.cell:iterateReferences(tes3.objectType.door) do
		if doorRef.object.id == shallNotPassDoor then
			local distance = doorRef.position:distance(creaPosition)
			if distance <= minDistance then
				minDistance = distance
				minDoorRef = doorRef
			end
		end
	end
	return minDistance, minDoorRef
end

local function skellyShallNotPass()
	if not catacombsCells[tes3.player.cell.id] then
		return
	end
	for creatureRef in tes3.player.cell:iterateReferences(tes3.objectType.creature) do
		if isCatacombsCreature[creatureRef.baseObject.id] then
			if creatureRef.mobile.isDead then
				return
			end
			if creatureRef.mobile.playerDistance > 4096 then
				return
			end
			local minDistance, minDoorRef = getDistanceOfClosestDoor(creatureRef.position)
			if minDistance < 256 then
				log:debug("%s min distance is %s", creatureRef.id, minDistance)
			end
			if minDistance < 160 then
				log:debug("%s is inside the door trigger area", creatureRef.id)
				if minDoorRef and minDoorRef.position:distance(tes3.player.mobile.position) > 160 then
					log:debug("player is outside the door trigger area", creatureRef.id)
					for nearbyCreatureRef in tes3.player.cell:iterateReferences(tes3.objectType.creature) do
						if nearbyCreatureRef.mobile.position:distance(creatureRef.mobile.position) < 512 or nearbyCreatureRef ==
						creatureRef then
							log:debug("distance between %s and %s is %s", creatureRef.id, nearbyCreatureRef.id,
							          nearbyCreatureRef.mobile.position:distance(creatureRef.mobile.position))
							if nearbyCreatureRef.leveledBaseReference then
								log:debug("%s is a leveled spawn from %s", nearbyCreatureRef.id, nearbyCreatureRef.leveledBaseReference.id)
								log:debug("%s previous position %s", nearbyCreatureRef.id, nearbyCreatureRef.position)
								nearbyCreatureRef.position = nearbyCreatureRef.leveledBaseReference.position
								log:debug("%s position repositioned %s", nearbyCreatureRef.id, nearbyCreatureRef.position)
							end
							minDoorRef.sceneNode:updateEffects()
							minDoorRef.orientation = minDoorRef.startingOrientation
							nearbyCreatureRef.mobile:stopCombat(true)
							if nearbyCreatureRef.mobile.inCombat then
								log:debug("%s stop combat failed", nearbyCreatureRef.id)
							end
						end
					end
				end
			end
		end
	end
end

--[[
    if the player is in the catacombs,
    if a skeleton is close to the door,
    and the player is not close to that door, 
    reposition them to their original position
    close the door,
    and stop combat,
]]

local function getPCCalmLevel()
	local level = 0
	for equipmentStack in tes3.iterate(tes3.player.object.equipment) do
		if calmLevel[equipmentStack.object.id] then
			level = level + calmLevel[equipmentStack.object.id]
		end
	end
	return level
end

local function calmGhosties()
	for _, cell in pairs(tes3.getActiveCells()) do
		-- if not catacombsCells[cell.id] then return end
		for reference in cell:iterateReferences(tes3.objectType.creature) do
			local mobile = reference.mobile
			local calmLevel = getPCCalmLevel()
			if calmLevel > 0 and isGhosty[reference.baseObject.id] then
				if not reference.data.OoGInitFight then
					reference.data.OoGInitFight = mobile.fight
				end
				if reference.data.OoGInitFight > 50 then
					mobile.fight = math.max(50, reference.data.OoGInitFight - calmLevel)
				end
			elseif calmLevel == 0 and reference.data.OoGInitFight and reference.data.OoGInitFight ~= mobile.fight then
				mobile.fight = reference.data.OoGInitFight
			end
		end
	end
end

event.register("initialized", function(e)
	event.register("simulate", skellyShallNotPass)
	-- event.register("simulate", calmGhosties)
	event.register("loaded", function()
		timer.start { iterations = -1, duration = 1, callback = calmGhosties }
	end)
end)

--[[
    Every second, 
    scan for any creature nearby,
    if the player is wearing Order of Ghosts armor,
    and if the creature is a ghost,
    store their initial fight value,
    if the ghost is hostile,
    set their fight value as initial fight value minus calmLevel, mininum is 50.
    if you are not wearing enough pieces of armor
    the ghost return being hostile
]]

--[[
    where to get the full set in a non violent way: 
    boots: in a chest in ghostgate, hall of ghosts bedroom
    bracers: in a chest in the training room in hall of the order
    cuirass: in a chest underwater in western catacombs
    greaves: in northmost catacomb room in western catacombs
    hood: in a chest in the training room in hall of the order
    pauldrons: on a chest in ghostgate, hall of ghosts bedroom
]]
