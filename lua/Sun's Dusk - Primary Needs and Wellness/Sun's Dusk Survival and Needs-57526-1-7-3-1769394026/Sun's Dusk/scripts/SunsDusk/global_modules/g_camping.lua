local sparklingWood = {}


local function replaceFirewood(object)
	if not object:isValid() or object.count < 1 then return end
	if types.Ingredient.objectIsInstance(object) or types.Miscellaneous.objectIsInstance(object) then
		if object.count > 1 or object.recordId == "sd_wood_publican" or object.recordId == "sd_wood_merchant" then
			local effectiveCount = object.count * (logItems[object.recordId] or 1)
			local campfireLevel = math.min(5, effectiveCount)
			local upgradedFire = "sd_wood_"..campfireLevel
			local pos = object.position
			local cell = object.cell
			local id = object.id
			local wastedCount = effectiveCount - campfireLevel
			if wastedCount >= 1 then
				for _, player in pairs(cell:getAll(types.Player)) do
					world.createObject("sd_wood_1", wastedCount):moveInto(types.NPC.inventory(player))
					break
				end
			end
			object:remove()
			--print(upgradedFire)
			local upgradedObject = world.createObject(upgradedFire)
			--print(upgradedObject)
			upgradedObject:teleport(cell, pos)
		end
	end
end


G_onUpdateJobs.camping = function(dt)
	--world.setSimulationTimeScale(0.2)
	-- Update falling wood physics
	local GRAVITY = -627  -- OpenMW gravity constant (negative Z)
	local SETTLE_TIME = 0.4  -- Time to align to ground in seconds
	
	for woodId, woodData in pairs(saveData.fallingWood) do
		local woodObject = woodData.woodObject
		--print(woodObject and woodObject:isValid() , woodObject.cell , woodData.elapsedTime == 0 , not woodObject.id:find("deleted"))
		if woodObject and woodObject:isValid() and not woodObject.id:find("deleted") then --and woodObject.enabled then
			if woodObject.cell then
				if woodData.phase == "falling" then
					-- Update velocity with gravity
					woodData.velocity = woodData.velocity + util.vector3(0, 0, GRAVITY * dt)
					
					-- Update position
					local newPos = woodObject.position + woodData.velocity * dt
					
					-- Track elapsed time
					woodData.elapsedTime = woodData.elapsedTime + dt
					
					-- Check if reached or passed ground
					if newPos.z <= woodData.targetPos.z+1 then
						-- Snap to ground position with landing rotation (0-30° off)
						--print(woodObject, woodObject.cell, woodData.targetPos, woodData.landingRotation)
						--print(woodObject.rotation, woodData.landingRotation)
						woodObject:teleport(woodObject.cell, woodData.targetPos, {
							rotation = woodData.landingRotation
						})
						
						-- Switch to settling phase
						woodData.phase = "settling"
						woodData.settleTimer = 0
					else
						-- Still falling - update position and rotation
						
						-- Calculate rotation based on angular velocity and elapsed time
						local totalAngle = woodData.angularVelocity * woodData.elapsedTime
						
						-- Create rotation around the random spin axis
						local spinAxis = util.vector3(woodData.rotAxisX, woodData.rotAxisY, woodData.rotAxisZ)
						local spinRotation = util.transform.rotate(totalAngle, spinAxis)
						
						-- Combine with starting rotation
						local currentRotation = spinRotation * woodData.startRotation
						
						woodObject:teleport(woodObject.cell, newPos, {
							rotation = currentRotation
						})
					end
					
				elseif woodData.phase == "settling" then
					woodData.settleTimer = woodData.settleTimer + dt
					
					-- Always interpolate (t clamps to 1.0 when timer exceeds SETTLE_TIME)
					local t = math.min(1, woodData.settleTimer / SETTLE_TIME)
					
					-- Extract Euler angles from both rotations
					local landingZ, landingY, landingX = woodData.landingRotation:getAnglesZYX()
					local targetZ, targetY, targetX = woodData.targetRotation:getAnglesZYX()
					
					-- Helper function to interpolate angles with proper wrapping
					local function lerpAngle(a, b, t)
						local diff = b - a
						while diff > math.pi do diff = diff - 2*math.pi end
						while diff < -math.pi do diff = diff + 2*math.pi end
						return a + diff * t
					end
					
					-- Interpolate each angle
					local interpZ = lerpAngle(landingZ, targetZ, t)
					local interpY = lerpAngle(landingY, targetY, t)
					local interpX = lerpAngle(landingX, targetX, t)
					
					-- Rebuild the Transform from interpolated angles (ZYX order)
					local interpRotation = util.transform.rotateZ(interpZ) 
						* util.transform.rotateY(interpY) 
						* util.transform.rotateX(interpX)
						
					-- AFTER interpolating, check if we're done
					if woodData.settleTimer >= SETTLE_TIME then
						woodObject:teleport(woodObject.cell, woodData.targetPos, {
							rotation = woodData.groundRotation
						})
						saveData.fallingWood[woodId] = nil
						local rndId = "sparklingWood"..math.random()
						sparklingWood[woodObject.id] = rndId
						
						if WOOD_SPARKLES then
							world.vfx.spawn(
								"meshes/SunsDusk/sparkle.nif",
								woodData.targetPos-v3(0,0,22),
								{
									scale = 0.33,
										vfxId = rndId
								}
							)
							
							async:newUnsavableSimulationTimer(2.5, function()
								if not woodObject:isValid() or woodObject.count == 0 then return end
								world.vfx.spawn(
									"meshes/SunsDusk/sparkle.nif",
									woodData.targetPos-v3(0,0,22),
									{
										scale = 0.33,
										vfxId = rndId
									}
								)
							end)
							async:newUnsavableSimulationTimer(5, function()
								if not woodObject:isValid() or woodObject.count == 0 then return end
								world.vfx.spawn(
									"meshes/SunsDusk/sparkle.nif",
									woodData.targetPos-v3(0,0,22),
									{
										scale = 0.33,
										vfxId = rndId
									}
								)
							end)
							async:newUnsavableSimulationTimer(7.5, function()
								if not woodObject:isValid() or woodObject.count == 0 then return end
								world.vfx.spawn(
									"meshes/SunsDusk/sparkle.nif",
									woodData.targetPos-v3(0,0,22),
									{
										scale = 0.33,
										vfxId = rndId
									}
								)
							end)
							async:newUnsavableSimulationTimer(10, function()
								sparklingWood[woodObject.id] = nil
							end)
						end
					else
						woodObject:teleport(woodObject.cell, woodData.targetPos, {
							rotation = interpRotation
						})
					end
				end
			else
				--print("err")
			end
		else
			-- Object was destroyed or disabled, remove from tracking
			saveData.fallingWood[woodId] = nil
		end
	end
	local now = world.getGameTime()
	for objectId, tbl in pairs(saveData.litFires) do
		local object = tbl[1]
		local timestamp = tbl[2]
		local timePassed = now - timestamp
		if timePassed > 2*time.hour then
			if object:isValid() and object.count > 0 then
				local amountOfLogs = tonumber(object.recordId:sub(-5,-5))
				local pos = object.position
				local cell = object.cell
				local newId = "sd_wood_"..(amountOfLogs-1).."_lit"
				if amountOfLogs == 1 then
					newId = "sd_coal_pile"
					pos = pos - v3(0,0,0)
				end
				object:remove()
				
				local upgradedObject = world.createObject(newId)
				upgradedObject:teleport(cell, pos)
				if newId ~= "sd_coal_pile" then
					saveData.litFires[upgradedObject.id] = {upgradedObject, timestamp + 2*time.hour}
				end
				saveData.litFires[objectId] = nil
			end
		end
	end
	if math.random() < 0.05 then
		for objectId, tbl in pairs(saveData.campingGear) do
			if now - tbl.time > time.day then
				if tbl.tent and tbl.tent:isValid() and tbl.tent.count > 0 then
					tbl.tent:remove()
				end
				if tbl.bedroll and tbl.bedroll:isValid() and tbl.bedroll.count > 0 then
					tbl.bedroll:remove()
				end
				saveData.campingGear[objectId] = nil
			end
		end
	end
end


G_onObjectActiveJobs.camping = function(object)
	if object.recordId:sub(1,8) == "sd_wood_" then-- or object.recordId == "sd_wood_publican" or object.recordId == "sd_wood_merchant" then
		table.insert(G_delayedUpdateJobs, {
			3,  -- Wait 3 ticks (same as the old 3-variable cascade)
			function()
				replaceFirewood(object)
			end
		})
	end
	if object.recordId == "sd_campingitem_tent" then
		local cell = object.cell
		if cellHasPublican(cell) then
			for _, player in pairs(cell:getAll(types.Player)) do
				player:sendEvent("SunsDusk_messageBox", {2, messageBoxes_campInCell[math.random(1,#messageBoxes_campInCell)]})
			end
			return 
		end
		local position = object.position
		local nearestPlayer
		local shortestDistance = math.huge
		for _, player in pairs(cell:getAll(types.Player)) do
			if not nearestPlayer then
				nearestPlayer = player
				shortestDistance = (player.position - position):length()
			elseif (player.position - position):length() < shortestDistance then
				nearestPlayer = player
				shortestDistance = (player.position - position):length()
			end
		end
		if nearestPlayer then
			local yaw = nearestPlayer.rotation:getYaw()
			local dir = v3(
				math.sin(yaw),
				math.cos(yaw),
				0
			):normalize()
			position = nearestPlayer.position + dir * 100 -- v3(0,0,2)
		end
		
		local rotation = object.rotation
		object:remove()
		local tent = world.createObject("sd_campingobject_tent", 1)
		tent:teleport(cell, position, {
			rotation = rotation,
			onGround = true
		})
		
		tent:setScale(0.45)
		local bedroll = world.createObject("sd_campingobject_bedrolltent", 1)
		bedroll:teleport(cell, position, {
			rotation = rotation,
			onGround = true
		})
		
		saveData.campingGear[tent.id] = {tent = tent, bedroll = bedroll, time = core.getGameTime()}
	elseif object.recordId == "sd_campingitem_bedroll" then
		local cell = object.cell
		if cellHasPublican(cell) then 
			for _, player in pairs(cell.Players) do
				player:sendEvent("SunsDusk_messageBox", {2, "Caius' words echoed... There's a time and place for everything, but not now."})
			end
			return 
		end
		local position = object.position
		local rotation = object.rotation
		object:remove()
		local bedroll = world.createObject("sd_campingobject_bedroll", 1)
		bedroll:teleport(cell, position, {
			rotation = rotation
		})
		saveData.campingGear[bedroll.id] = {bedroll = bedroll, time = core.getGameTime()}
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Woodcutting														  │
-- ╰──────────────────────────────────────────────────────────────────────╯

-- Spawn falling wood items in the air
local function spawnFallingWood(data)
	local itemId = data.itemId
	local spawnData = data.spawnData
	local player = data.player
	
	if not itemId or not spawnData or not player then
		return
	end
	
	-- Use the player's cell directly
	local targetCell = player.cell
	
	local GRAVITY = 627  -- openmw gravity magnitude (positive)
	
	-- Spawn each wood piece in the air and track for physics
	for _, pieceData in ipairs(spawnData) do
		-- Random number of spins between 0.5 and 1.5
		local totalSpins = 0.5 + math.random() * 1.0
		
		-- Calculate fall time using physics
		local fallHeight = pieceData.airPosition.z - pieceData.groundPosition.z
		local fallTime = math.sqrt(2 * fallHeight / GRAVITY)
		
		-- Calculate angular velocity
		local angularVelocity = (totalSpins * math.pi * 2) / fallTime
		
		-- Random rotation axis (normalised)
		local rotAxisX = (math.random() - 0.5) * 2
		local rotAxisY = (math.random() - 0.5) * 2
		local rotAxisZ = (math.random() - 0.5) * 2
		local axisLength = math.sqrt(rotAxisX*rotAxisX + rotAxisY*rotAxisY + rotAxisZ*rotAxisZ)
		if axisLength > 0 then
			rotAxisX = rotAxisX / axisLength
			rotAxisY = rotAxisY / axisLength
			rotAxisZ = rotAxisZ / axisLength
		else
			rotAxisX, rotAxisY, rotAxisZ = 0, 0, 1
		end
		
		-- Calculate landing rotation (0-30° off from target)
		local offsetAngle = math.random() * math.pi / 6
		local offsetAxis = util.vector3(
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2
		):normalize()
		local landingRotation = pieceData.groundRotation * 
							util.transform.rotate(offsetAngle, offsetAxis)
		
		-- Calculate total spin that will occur during fall
		local totalSpinAngle = totalSpins * math.pi * 2
		local spinAxis = util.vector3(rotAxisX, rotAxisY, rotAxisZ)
		local totalSpinRotation = util.transform.rotate(totalSpinAngle, spinAxis)
		
		-- Work BACKWARDS: what starting rotation will spin into landingRotation?
		local startRotation = totalSpinRotation:inverse() * landingRotation
		
		local woodItem = world.createObject(itemId, 1)
		
		-- Place at air position with starting rotation
		woodItem:teleport(
			targetCell,
			pieceData.airPosition,
			{
				rotation = startRotation
			}
		)
		
		-- Track this wood for physics simulation
		saveData.fallingWood[woodItem.id] = {
			woodObject = woodItem,
			startPos = pieceData.airPosition,
			targetPos = pieceData.groundPosition,
			velocity = util.vector3(0, 0, 0),
			targetRotation = pieceData.groundRotation,
			landingRotation = landingRotation,
			startRotation = startRotation,
			angularVelocity = angularVelocity,
			rotAxisX = rotAxisX,
			rotAxisY = rotAxisY,
			rotAxisZ = rotAxisZ,
			totalSpins = totalSpins,
			elapsedTime = 0,
			phase = "falling",  -- "falling", "settling"
			settleTimer = 0
		}
	end
end

-- Remove tree and track in saveData
local function removeTree(data)
	local tree = data.tree
	
	if not tree then
		return
	end
	
	local recordId = tree.recordId
	local cellId = tree.cell.id or ""
	local position = tree.position
	local rotation = tree.rotation
	
	-- Get current game time
	local gameTime = core.getGameTime()
	
	-- Create unique ID for this tree removal
	local treeId = recordId .. "_" .. cellId .. "_" .. tostring(position.x) .. "_" .. tostring(position.y) .. "_" .. tostring(position.z)
	
	-- Store tree removal data
	saveData.removedTrees = saveData.removedTrees or {}
	saveData.removedTrees[treeId] = {
		gameTime = gameTime,
		recordId = recordId,
		cellId = cellId,
		position = {
			x = position.x,
			y = position.y,
			z = position.z
		},
		rotation = {
			x = rotation.x,
			y = rotation.y,
			z = rotation.z
		}
	}
	
	tree:remove()
end

local campfireUpgrades = {
    ["sd_wood_1"] 	  = "sd_wood_2",
    ["sd_wood_2"] 	  = "sd_wood_3",
	["sd_wood_3"] 	  = "sd_wood_4",
	["sd_wood_4"] 	  = "sd_wood_5",
	["sd_wood_5"] 	  = false,
    ["sd_wood_1_lit"] = "sd_wood_2_lit",
    ["sd_wood_2_lit"] = "sd_wood_3_lit",
    ["sd_wood_3_lit"] = "sd_wood_4_lit",
    ["sd_wood_4_lit"] = "sd_wood_5_lit",
    ["sd_wood_5_lit"] = false,
}

local function upgradeFire(data)
	local player = data[1]
	local object = data[2]
	
	local upgradedFire = campfireUpgrades[object.recordId]
	if not upgradedFire then return end
	local logInInv = types.NPC.inventory(player):find("sd_wood_1") or types.NPC.inventory(player):find("sd_wood_publican") or types.NPC.inventory(player):find("sd_wood_merchant")
	if not logInInv then return end
	
	logInInv:remove(1)
	
	local pos = object.position
	local cell = object.cell
	local id = object.id
	
	object:remove()
	local upgradedObject = world.createObject(upgradedFire)
    upgradedObject:teleport(cell, pos)
	if upgradedObject.recordId:sub(-4) == "_lit" then
		--local time = -- only add to time instead of resetting but w/e
		saveData.litFires[id] = nil
		saveData.litFires[upgradedObject.id] = {upgradedObject, world.getGameTime()}
	end
end

local function igniteFire(data)
	local player = data[1]
	local object = data[2]
	
	local isValid = campfireUpgrades[object.recordId]
	if isValid == nil then return end
	local litId = object.recordId.."_lit"
	if not types.Light.records[litId] then return end
	local pos = object.position
	local cell = object.cell
	
	object:remove()
	local upgradedObject = world.createObject(litId)
    upgradedObject:teleport(cell, pos)
	saveData.litFires[upgradedObject.id] = {upgradedObject, world.getGameTime()}
	
	for _, player in pairs(cell:getAll(types.Player)) do
		player:sendEvent("SunsDusk_registerFire", upgradedObject)
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Firewood															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function lootIngredient(item, player)
	local woodCount = logItems[item.recordId]
	if woodCount then
		-- 0.51 ONLY
		if sparklingWood[item.id] then
			if world.vfx.remove then
				world.vfx.remove(sparklingWood[item.id])
			end
			sparklingWood[item.id] = nil
		end
		if woodCount > 1 then
			if item.count > 0 then
				world.createObject("sd_wood_1", woodCount):moveInto(types.NPC.inventory(player))
				player:sendEvent("SunsDusk_playSound", "Item Misc Up")
				item:remove()
			end
			return false
		end
	end
end

I.Activation.addHandlerForType(types.Ingredient, lootIngredient)

local function convertPurchasedWood(player)

	do return end -- RETURN
	
	local inv	= types.NPC.inventory(player)
	for _, item in pairs(inv:getAll(types.Miscellaneous)) do
		if item.recordId == "sd_wood_merchant" then
			local count = item.count
			if item:isValid() and item.count > 0 then
				item:remove()
				world.createObject("sd_wood_1", count):moveInto(inv)
				log(3,"converted "..count.." purchased firewood")
			end
		end
	end	
	for _, item in pairs(inv:getAll(types.Ingredient)) do
		if item.recordId == "sd_wood_publican" then
			local count = item.count
			if item:isValid() and item.count > 0 then
				item:remove()
				world.createObject("sd_wood_1", count):moveInto(inv)
				log(3,"converted "..count.." purchased firewood")
			end
		end
	end	
end


-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Spriggan															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function spawnSpriggan(data)
	local player = data[1]
	local tree = data[2]
	
		-- Position at random offset from player
	local playerPos = player.position
	local angle = math.random() * math.pi * 2
	local distance = 100 + math.random() * 200
	
	local spawnPos = util.vector3(
		playerPos.x + math.cos(angle) * distance,
		playerPos.y + math.sin(angle) * distance,
		playerPos.z + 100
	)
	
	if types.LevelledCreature.records["t_sky_lvl_spriggans"] then
		local spriggan = world.createObject("t_sky_lvl_spriggans", 1)
		if spriggan then
			spriggan:teleport(player.cell, spawnPos)
		end
		return
	end
	
	local playerLevel = types.Actor.stats.level(player).current
	
	-- Collect all spriggans with their levels
	local spriggans = {}
	for _, creatureRecord in pairs(types.Creature.records) do
		if (creatureRecord.id:find("spriggan") or creatureRecord.name:lower():find("spriggan")) and not creatureRecord.id:find("unique") and not creatureRecord.id:find("bm_spriggan_co") then
			table.insert(spriggans, {
				id = creatureRecord.id,
				level = creatureRecord.level or 1 -- level is not accessible yet
			})
		end
	end
	
	if #spriggans == 0 then
		print("Warning: No spriggans found!")
		return
	end
	
	-- Find minimum level across all spriggans
	local minLevel = math.huge
	for _, sprig in ipairs(spriggans) do
		minLevel = math.min(minLevel, sprig.level)
	end
	
	-- Determine level cap: if player is weaker than all spriggans, cap at minimum
	-- Otherwise allow up to playerLevel + 5
	local maxAllowedLevel = playerLevel < minLevel and minLevel or playerLevel + 5
	
	-- Build candidate pool
	local candidates = {}
	for _, sprig in ipairs(spriggans) do
		if sprig.level <= maxAllowedLevel then
			--print(sprig.id, sprig.level)
			table.insert(candidates, sprig.id)
		end
	end
	
	-- Pick random candidate and spawn
	local selectedId = candidates[math.random(#candidates)]
	local spriggan = world.createObject(selectedId, 1)
	spriggan:teleport(player.cell, spawnPos)
end


local function destroyCamp(object)
	local objectId = object.id
	local tbl = saveData.campingGear[objectId]
	if tbl then
		if tbl.tent and tbl.tent:isValid() and tbl.tent.count > 0 then
			tbl.tent:remove()
		end
		if tbl.bedroll and tbl.bedroll:isValid() and tbl.bedroll.count > 0 then
			tbl.bedroll:remove()
		end
		saveData.campingGear[objectId] = nil
	end
end


G_onLoadJobs.camping = function(data)
	saveData.removedTrees	= saveData.removedTrees	or {}
	saveData.fallingWood	= saveData.fallingWood	or {}
	
	if not saveData.litFires then
		saveData.litFires = {}
	end
	
	if not saveData.campingGear then
		saveData.campingGear = {}
	end
end

G_eventHandlers.SunsDusk_spawnFallingWood					= spawnFallingWood
G_eventHandlers.SunsDusk_removeTree							= removeTree
G_eventHandlers.SunsDusk_igniteFire							= igniteFire
G_eventHandlers.SunsDusk_upgradeFire						= upgradeFire
G_eventHandlers.SunsDusk_convertPurchasedWood				= convertPurchasedWood
G_eventHandlers.SunsDusk_spawnSpriggan						= spawnSpriggan
G_eventHandlers.SunsDusk_destroyCamp						= destroyCamp