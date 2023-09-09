---@diagnostic disable: cast-local-type, assign-type-mismatch, undefined-field
--[[
Visible equipped amulets & rings
Morrowind Code Patch option to enable 1 extra on-use ring slot highly suggested
--]]

-- begin configurable parameters
local defaultConfig = {
viewAmuletLevel = 4, -- 0 = Not visible, 1 = bare chest, 2 = Shirt, 3 = Cuirass, 4 = Robe
viewRingsLevel = 3, -- 0 = Not visible, 1 = Bare Hands, 2 = Gloves, 3 = Gauntlets
maxVisibleRings = 3, -- max visible rings
--[[
Note: in theory...
https://discord.com/channels/210394599246659585/381219559094616064/1065639934683258891
-unlimited- rings
mwse.memory.writeBytes{ address = 0x495A42, bytes = { 0x90, 0xE9 } }

https://discord.com/channels/210394599246659585/381219559094616064/1065648256836718633

mwse.memory.writeBytes{ address = 0x495553, bytes = { 0x90, 0xE9 } }
Probably not worth though
]]
displayLevel = 3, -- 0 = None, 1 = Equipped by Player, 2 = Equipped by NPCs, 3 = In NPC's inventory
amuletForwardOffset = 0, -- amulet position forward offset (X 0.03)
amuletSideOffset = 0, -- Amulet position side offset (X 0.03)
amuletVerticalOffset = 0, -- Amulet position vertical offset (X 0.03)
amuletScale = 100, -- default: 100%
ringForwardOffset = 0, -- ring position forward offset (X 0.0075)
ringSideOffset = 0, -- ring position side offset (X 0.0075)
ringScale = 100, -- default: 100%
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium 3 = High
debugMessages = false, -- in-game debug messages
}
-- end configurable parameters

local maxRingSlots = 2 -- updated in modConfigReady()
local RING_SLOT_NAMES = {}
RING_SLOT_NAMES[1] = 'Bip01 L Finger1'
RING_SLOT_NAMES[2] = 'Bip01 R Finger1'
RING_SLOT_NAMES[3] = 'Bip01 L Finger2'
RING_SLOT_NAMES[4] = 'Bip01 L Finger3' -- bah. 1st person view has different finger nodes, go figure

local author = 'abot'
local modName = 'Vanity'
local modPrefix = author .. '/'.. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

-- 2nd parameter advantage: anything not defined in the loaded file inherits the value from my_default_config
local config = mwse.loadConfig(configName, defaultConfig)
if config.debugLevel then  -- update legacy
	config.logLevel = config.debugLevel
	config.debugLevel = nil
end

-- updated in modConfigReady()
local displayLevel = config.displayLevel
local logLevel = config.logLevel

local function dm(str, ...)
	if logLevel <= 0 then
		return
	end
	local s = modPrefix..': '..tostring(str):format(...)
	print(s)
	if config.debugMessages then
		tes3.messageBox(s)
	end
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

-- set in loaded()
local player
local mobilePlayer
local firstPersonNode

local ARMO_TYPE = tes3.objectType.armor
local CLOTH_TYPE = tes3.objectType.clothing
local NPC_TYPE = tes3.objectType.npc

local AMULET_SLOT = tes3.clothingSlot.amulet
local RING_SLOT = tes3.clothingSlot.ring
local ROBE_SLOT = tes3.clothingSlot.robe
local SHIRT_SLOT = tes3.clothingSlot.shirt
local LEFT_GLOVE_SLOT = tes3.clothingSlot.leftGlove
local RIGHT_GLOVE_SLOT = tes3.clothingSlot.rightGlove

local CUIRASS_SLOT = tes3.armorSlot.cuirass
local LEFT_GAUNTLET_SLOT = tes3.armorSlot.leftGauntlet
local RIGHT_GAUNTLET_SLOT = tes3.armorSlot.rightGauntlet

local CHILD_NODE_NAME = 'ab01node'

--[[
local visualsCache = {} -- visuals cache, cleared in loaded()
local visualsCacheMaxSize = 50

local maxUsedCache = 0

local function cleanVisualCache()
	if logLevel >= 2 then
		dm("visualsCache cleared")
	end
	-- not ideal, but fast
	for key in pairs(visualsCache) do
		visualsCache[key] = nil
	end
	visualsCache = {} -- clear visual nodes cache
end

local function getVisual(mesh)
	local visual = visualsCache[mesh]
	if not visual then
		visual = tes3.loadMesh(mesh, false) -- avoid caching by default
		if visual then
			local cacheSize = table.size(visualsCache)
			if cacheSize > maxUsedCache then
				maxUsedCache = cacheSize
				if logLevel >= 2 then
					dm("maxUsedCache = %s", maxUsedCache)
				end
			end
			if cacheSize > visualsCacheMaxSize then
				cleanVisualCache()
			end
			visualsCache[mesh] = visual
		end
	end
	if not visual then
           visual = tes3.loadMesh(mesh)
        end
	if visual then
		visual = visual:clone()
		visual:clearTransforms()
		visual.name = CHILD_NODE_NAME
	end
	return visual
end
]]

local function getVisual(mesh)
	local visual = tes3.loadMesh(mesh)
	if visual then
		visual = visual:clone()
		visual:clearTransforms()
		visual.name = CHILD_NODE_NAME
	end
	return visual
end

-- in NIFSkope degrees rotations, Z = Roll = Blue Axis, Y = Yaw = Green Axis, X = Pitch = Red Axis
-- rotation is axis-order sensible
local function rotateZYX(node, zDeg, yDeg, xDeg)
	local m
	if not (zDeg == 0) then
		m = tes3matrix33.new()
		m:toRotationZ(math.rad(zDeg))
		node.rotation = node.rotation * m
	end
	if not (yDeg == 0) then
		m = tes3matrix33.new()
		m:toRotationY(math.rad(yDeg))
		node.rotation = node.rotation * m
	end
	if not (xDeg == 0) then
		m = tes3matrix33.new()
		m:toRotationX(math.rad(xDeg))
		node.rotation = node.rotation * m
	end
end

--[[local function updateNodes(attachNode, sceneNode)
	attachNode:update()
	attachNode:updateEffects()
	sceneNode:update()
	sceneNode:updateEffects()
end]]
local function updateNodes(sceneNode)
	sceneNode:update()
	sceneNode:updateEffects()
	---sceneNode:updateProperties()
end

local function updateVisuals(sceneNode, attachNode, visual, item)
	attachNode:attachChild(visual, true)
	if item.enchantment then -- shiny! a good reason to disable No-Glow texture mods
---@diagnostic disable-next-line: redundant-parameter
		tes3.worldController:applyEnchantEffect(visual, item.enchantment)
		visual:updateProperties()
		visual:updateEffects()
	end
	updateNodes(sceneNode)
end

local function clearPreviousVisual(attachNode)
	local child = attachNode:getObjectByName(CHILD_NODE_NAME)
	if child then
		if logLevel >= 3 then
			dm("clearPreviousVisual: attachNode:detachChild(attachNode = %s, child = %s)", attachNode.name, child.name)
		end
		attachNode:detachChild(child)
	end
end

local function updateRingNode(sceneNode, item, ringSlotNum, scale, dy, dz)
	local slotName = RING_SLOT_NAMES[ringSlotNum]
	if ringSlotNum == 3 then
		if sceneNode == firstPersonNode then
			slotName = RING_SLOT_NAMES[4] -- 1st person view has different finger nodes
		end
	end
	---assert(slotName)
	local attachNode = sceneNode:getObjectByName(slotName)
	if not attachNode then
		return
	end
	clearPreviousVisual(attachNode)
	if not item then
		if logLevel >= 3 then
			dm("updateRingNode cleared sceneNode = %s, attachNode = %s, slot = %s", sceneNode.name, attachNode.name, ringSlotNum)
		end
		updateNodes(sceneNode)
		return
	end

	if logLevel >= 3 then
		dm("updateRingNode drawn: item = %s, sceneNode = %s, attachNode = %s, slot = %s", item.id, sceneNode.name, attachNode.name, ringSlotNum)
	end
	local mesh = item.mesh
	if not mesh then
		return
	end
	mesh = mesh:lower()

	local visual = getVisual(mesh)

	if ringSlotNum >= 3 then
		dz = dz + 0.05 -- a little more for external finger
	end
	if string.find(mesh,'artifact_amulet_hring_01', 1, true) then
		visual.scale = 0.34 * scale
		visual.translation.y = (dy - 1.15) * scale -- ring forward displacement
		visual.translation.z = (dz + 0.09) * scale -- ring side displacement
		rotateZYX(visual, 180, 90, 0)
	elseif string.find(mesh,'artifact_bloodring_01', 1, true) then
		visual.scale = 0.32 * scale
		visual.translation.y = (dy - 0.83) * scale -- ring forward displacement
		visual.translation.z = (dz + 0.1) * scale -- ring side displacement
		rotateZYX(visual, 0, 90, 0)
	elseif string.find(mesh,'artifact_ring_soul_01', 1, true) then
		visual.scale = 0.34 * scale
		visual.translation.y = (dy - 1.15) * scale -- ring forward displacement
		visual.translation.z = (dz + 0.1) * scale -- ring side displacement
		rotateZYX(visual, 0, 90, 0)
	---elseif orFind(mesh,'_art_ring_|ing_extravagant|ing_exquisite', true) then
	elseif string.multifind(mesh, {'_art_ring_', 'ing_extravagant', 'ing_exquisite'}, 1, true) then
		visual.scale = 0.5 * scale
		visual.translation.y = (dy + 0.43) * scale -- ring backward displacement
		visual.translation.z = (dz - 0.06) * scale -- ring side displacement
		rotateZYX(visual, -45, 89, 0)
	else
		visual.scale = 0.51 * scale
		visual.translation.y = (dy - 0.22) * scale -- ring backward displacement
		visual.translation.z = (dz + 0.065) * scale -- ring side displacement
		rotateZYX(visual, 0, 90, 0)
	end
	visual.translation.x = 1.7 -- ring position along finger length

	updateVisuals(sceneNode, attachNode, visual, item)

end

local function getEquippedChestLevel(npcRef) -- 1 = bare chested, 2 = shirt, 3 = cuirass, 4 = robe
	if tes3.getEquippedItem({ actor = npcRef, objectType = CLOTH_TYPE, slot = ROBE_SLOT }) then
		return 4
	end
	if tes3.getEquippedItem({ actor = npcRef, objectType = ARMO_TYPE, slot = CUIRASS_SLOT }) then
		return 3
	end
	if tes3.getEquippedItem({ actor = npcRef, objectType = CLOTH_TYPE, slot = SHIRT_SLOT }) then
		return 2
	end
	return 1
end

local function getEquippedLeftHandLevel(npcRef) -- 1 = bare hands, 2 = gloves, 3 = gauntlets
	if tes3.getEquippedItem({ actor = npcRef, objectType = ARMO_TYPE, slot = LEFT_GAUNTLET_SLOT }) then
		return 3
	end
	if tes3.getEquippedItem({ actor = npcRef, objectType = CLOTH_TYPE, slot = LEFT_GLOVE_SLOT }) then
		return 2
	end
	return 1
end

local function getEquippedRightHandLevel(npcRef) -- 1 = bare hands, 2 = gloves, 3 = gauntlets
	if tes3.getEquippedItem({ actor = npcRef, objectType = ARMO_TYPE, slot = RIGHT_GAUNTLET_SLOT }) then
		return 3
	end
	if tes3.getEquippedItem({ actor = npcRef, objectType = CLOTH_TYPE, slot = RIGHT_GLOVE_SLOT }) then
		return 2
	end
	return 1
end

local function updateRingVisual(npcRef, item, ringSlotNum)
	local sceneNode = npcRef.sceneNode
	local scale = 1
	local level
	if ringSlotNum == 2 then
		level = getEquippedRightHandLevel(npcRef)
	else
		level = getEquippedLeftHandLevel(npcRef)
	end
	if level == 3 then
		scale = 1.27
	elseif level == 2 then
		scale = 1.18
	end

	local yOffset = -0.0075 * config.ringForwardOffset
	local zOffset = 0.0075 * config.ringSideOffset
	scale = scale * config.ringScale * 0.01
	updateRingNode(sceneNode, item, ringSlotNum, scale, yOffset, zOffset)
	if npcRef == player then
		updateRingNode(firstPersonNode, item, ringSlotNum, scale * 1.09, yOffset, zOffset)
	end
end

local function updateAmuletNode(sceneNode, item, scale, xOffset, yOffset, zOffset)
	---tes3.messageBox("item = %s", item.id)
	local attachNode = sceneNode:getObjectByName('Bip01 Neck')
	if not attachNode then
		return
	end
	---dm("clearPreviousVisual(attachNode)")
	clearPreviousVisual(attachNode)
	if not item then
		updateNodes(sceneNode)
		return
	end

	local mesh = item.mesh
	if not mesh then
		return
	end
	mesh = mesh:lower()

	local visual = getVisual(mesh)

	if string.find(mesh, '_usheeja.nif', 1, true) then
		visual.scale = 0.4 * scale
		visual.translation.y = yOffset + 4.9 -- forward
		visual.translation.z = zOffset + 0.6 -- side
		xOffset = xOffset + 0.1
		rotateZYX(visual, 171, -167, 5)
	elseif string.find(mesh, '_htrime_01', 1, true) then
		visual.scale = 0.45 * scale
		visual.translation.y = yOffset + 5.6 -- forward
		visual.translation.z = zOffset - 0.3 -- side
		xOffset = xOffset + 0.6
		rotateZYX(visual, 100, 90, 42)
	elseif string.find(mesh, '_hthrum_01', 1, true) then
		visual.scale = 0.54 * scale
		visual.translation.y = yOffset + 4.85 -- forward
		visual.translation.z = zOffset -- side
		xOffset = xOffset - 0.65
		rotateZYX(visual, 100, 90, 40)
	elseif string.find(mesh, 'teeth_urshilaku', 1, true) then
		visual.scale = 0.639 * scale
		visual.translation.y = yOffset + 5.2 -- forward
		visual.translation.z = zOffset - 0.44 -- side
		rotateZYX(visual, 100, 90, 42)
	---elseif orFind(mesh, '_hfire_01|_hheal_01', true) then
	elseif string.multifind(mesh, {'_hfire_01', '_hheal_01'}, 1, true) then
		visual.scale = 0.6 * scale
		visual.translation.y = yOffset + 8.1 -- forward
		visual.translation.z = zOffset -- side
		xOffset = xOffset - 1.8
		rotateZYX(visual, 100, 90, 132)
	else
		visual.scale = 0.71 * scale
		visual.translation.y = yOffset + 4.0 -- forward
		visual.translation.z = zOffset - 0.44 -- side
		rotateZYX(visual, 100, 90, 42)
	end
	visual.translation.x = xOffset -- vertical

	updateVisuals(sceneNode, attachNode, visual, item)
end

local function updateAmuletVisual(npcRef, item)
	local sceneNode = npcRef.sceneNode
	local xOffset = (config.amuletVerticalOffset * 0.03) + 0.6
	local yOffset = (config.amuletForwardOffset * 0.03) - 0.1
	local zOffset = config.amuletSideOffset * 0.03
	local scale = config.amuletScale * 0.01
	if item then
		if logLevel >= 3 then
			dm("updateAmuletVisual(npc = %s %s, item=%s)", npcRef.id, npcRef.object.name, item.id)
		end
	end
	updateAmuletNode(sceneNode, item, scale, xOffset, yOffset, zOffset)
	if npcRef == player then -- needed to display on paperdoll
		updateAmuletNode(firstPersonNode, item, scale, xOffset, yOffset, zOffset)
	end
end

local function clearVisibleRing(npcRef, ringSlotNum)
	updateRingNode(npcRef.sceneNode, nil, ringSlotNum, 1, 0, 0)
	if npcRef == player then
		updateRingNode(firstPersonNode, nil, ringSlotNum, 1, 0, 0)
	end
end

local function clearVisibleRings(npcRef)
	for ringSlotNum = 1, maxRingSlots do
		clearVisibleRing(npcRef, ringSlotNum)
	end
end

local function leftRingsAllowed(npcRef)
	return config.viewRingsLevel >= getEquippedLeftHandLevel(npcRef)
end

local function rightRingsAllowed(npcRef)
	return config.viewRingsLevel >= getEquippedRightHandLevel(npcRef)
end

local function checkRing(npcRef, stack, slot, skipCleaning, leftAllowed, rightAllowed) -- output: 0 = not valid, 1 = ring slot cleaned, 2 = ring slot drawn
	local obj = stack.object
	if not obj then
		assert(obj)
		return 0
	end
	local objType = obj.objectType
	if not objType then
		assert(objType)
		return 0
	end
	if not (objType == CLOTH_TYPE) then
		return 0
	end
	local objSlot = obj.slot
	if not objSlot then
		assert(objSlot)
		return 0
	end
	if not (objSlot == RING_SLOT) then
		return 0
	end
	if not obj.mesh then
		assert(obj.mesh)
		return 0
	end
	if not skipCleaning then
		clearVisibleRing(npcRef, slot)
	end
	local ok
	if slot == 2 then
		ok = rightAllowed
	else
		ok = leftAllowed
	end
	if not ok then
		return 1
	end
	if logLevel >= 3 then
		dm("checkRing updateRingVisual(npc = %s %s, item=%s, slot=%s)", npcRef.id, npcRef.object.name, obj.id, slot)
	end
	updateRingVisual(npcRef, obj, slot)
	return 2
end

local function checkRings(npcRef)
	if (displayLevel < 2)
	and (not (npcRef == player)) then
		return
	end
	local maxSlot = config.maxVisibleRings
	local usedRingSlots = {}
	local leftAllowed = leftRingsAllowed(npcRef)
	local rightAllowed = rightRingsAllowed(npcRef)
	local result
	local skipCleaning = false
	local slot = 1
	-- check for equipped rings first
	for _, stack in pairs(npcRef.object.equipment) do -- pairs, better safe than sorry
		if not usedRingSlots[slot] then
			result = checkRing(npcRef, stack, slot, skipCleaning, leftAllowed, rightAllowed)
			if result == 2 then
				usedRingSlots[slot] = result
				if logLevel >= 2 then
					dm("checkRings(npcRef = %s %s) %s %s slot %s", npcRef.id, npcRef.object.name, stack.object.id, stack.object.name, slot)
				end
				if slot < maxSlot then
					slot = slot + 1
					skipCleaning = false
				else
					break
				end
			elseif result == 1 then
				skipCleaning = true
			end
		end
	end
	if npcRef == player then
		return -- it is player, stop here
	end
	if displayLevel < 3 then
		return
	end
	if #usedRingSlots >= maxSlot then
		return
	end
	skipCleaning = false
	slot = 1
	-- for NPCs, check also just rings in inventory to fill free visual ring slots

	local inventory = npcRef.object.inventory
	local items = inventory.items
	local stack
	--- for _, stack in pairs(npcRef.object.inventory) do -- needs pairs!
	for i = 1, #items do
		if not usedRingSlots[slot] then
			stack = items[i]
			result = checkRing(npcRef, stack, slot, skipCleaning, leftAllowed, rightAllowed)
			if result == 2 then
				usedRingSlots[slot] = result
				if logLevel >= 2 then
					dm("checkRings(npcRef = %s %s) %s %s slot %s", npcRef.id, npcRef.object.name, stack.object.id, stack.object.name, slot)
				end
				if slot < maxSlot then
					slot = slot + 1
					skipCleaning = false
				else
					return
				end
			elseif result == 1 then
				skipCleaning = true
			end
		end
	end
end

local function checkAmuletStack(npcRef, stack) -- return true if amulet visual has been updated
	local obj = stack.object
	if not obj then
		assert(obj)
		return false
	end
	local objType = obj.objectType
	if not objType then
		assert(objType)
		return false
	end
	if not (objType == CLOTH_TYPE) then
		return false
	end
	local objSlot = obj.slot
	if not objSlot then
		assert(objSlot)
		return false
	end
	if not (objSlot == AMULET_SLOT) then
		return false
	end
	if not obj.mesh then
		assert(obj.mesh)
		return false
	end
	updateAmuletVisual(npcRef, obj)
	return true
end

local function updateAmulet(npcRef)
	if (displayLevel < 2)
	and (not (npcRef == player)) then
		return
	end
	-- check for equipped amulet first
	local st = tes3.getEquippedItem({ actor = npcRef, objectType = CLOTH_TYPE, slot = AMULET_SLOT })
	local obj
	if st then
		obj = st.object
		if obj then
			if not obj.mesh then
				obj = nil
			end
		end
	end
	updateAmuletVisual(npcRef, obj)
	if obj then
		if logLevel >= 2 then
			dm("updateAmulet(npcRef = %s %s) %s %s amulet", npcRef.id, npcRef.object.name, obj.id, obj.name)
		end
		return
	end
	if npcRef == player then
		return
	end
	if displayLevel < 3 then
		return
	end
	-- for NPCs, check also just amulet in inventory

	local items = npcRef.object.inventory.items
	local stack
	--- for _, stack in pairs(npcRef.object.inventory) do -- needs pairs!
	for i = 1, #items do
		stack = items[i]
		if checkAmuletStack(npcRef, stack) then
			if logLevel >= 2 then
				dm("updateAmulet(npcRef = %s %s) %s %s amulet", npcRef.id, npcRef.object.name, stack.object.id, stack.object.name)
			end
			return
		end
	end
end

local function amuletAllowed(npcRef)
	return config.viewAmuletLevel >= getEquippedChestLevel(npcRef)
end

local function checkAmulet(npcRef)
	if amuletAllowed(npcRef) then
		updateAmulet(npcRef)
	else
		updateAmuletVisual(npcRef, nil)
	end
end

local function checkEquipment(npcRef, item, itemUnequipped)
	if not npcRef then
		return
	end
	local obj = npcRef.baseObject
	local objType = obj.objectType
	if not objType then
		return
	end
	if not (objType == NPC_TYPE) then
		return
	end
	if not item then
		return
	end
	local itemType = item.objectType
	if not itemType then
		return
	end
	local slot = item.slot
	if not slot then
		return
	end

	if itemType == CLOTH_TYPE then
		if (slot == ROBE_SLOT)
		or (slot == SHIRT_SLOT)
		or (slot == AMULET_SLOT) then
			checkAmulet(npcRef)
		elseif (slot == RING_SLOT) then
			if itemUnequipped then
				for ringSlotNum = 1, maxRingSlots do
					clearVisibleRing(npcRef, ringSlotNum)
				end
			end
			checkRings(npcRef)
		elseif (slot == LEFT_GLOVE_SLOT)
			or (slot == RIGHT_GLOVE_SLOT) then
			checkRings(npcRef)
		end
		return
	end

	if itemType == ARMO_TYPE then
		if (slot == CUIRASS_SLOT) then
			checkAmulet(npcRef)
		elseif (slot == LEFT_GAUNTLET_SLOT)
			or (slot == RIGHT_GAUNTLET_SLOT) then
			checkRings(npcRef)
		end
	end

end

---local skipEquipEvents = false

local function initEquipment(npcRef)
	---mwse.log('initEquipment("%s")', npcRef.id)
	if displayLevel == 0 then
		return
	end
	---assert(npcRef)
	clearVisibleRings(npcRef)
	updateAmuletVisual(npcRef, nil) -- clear amulet
	local obj, objType, objSlot
	local amuletCount = 0
	local ringCount = 0
	for _, stack in pairs(npcRef.object.equipment) do
		obj = stack.object
		objType = obj.objectType
		if objType then
			if objType == CLOTH_TYPE then
				objSlot = obj.slot
				if objSlot then
					if (objSlot == RING_SLOT) then
						ringCount = ringCount + 1
						checkEquipment(npcRef, obj, false)
					elseif (objSlot == AMULET_SLOT) then
						amuletCount = amuletCount + 1
						checkEquipment(npcRef, obj, false)
					end -- if (objSlot ==
				end -- if objSlot
			end-- if objType ==
		end -- if objType
	end -- for _, stack
	return amuletCount, ringCount
end

-- for non-player NPCs, show rings and amulet even if not equipped just for prettiness
-- as forcing them to equip would be not only complicated but often not good
-- as equipped things are not accessible from NPC inventory (e.g. vendors)
local function initNPCClothing(npcRef, equippedAmuletCount, equippedRingsCount)
	local object = npcRef.object
	if not object then
		return
	end
	local inventory = object.inventory
	if not inventory then
		return
	end

	local obj, objType, objSlot
	local amuletFound = equippedAmuletCount > 0
	local ringFound = equippedRingsCount >= maxRingSlots
	local ringCount = equippedRingsCount
	if logLevel >= 3 then
		dm("initNPCClothing(npc = %s %s amulets = %s rings = %s)", npcRef.id, npcRef.object.name, equippedAmuletCount, equippedRingsCount)
	end
	local items = inventory.items
	local stack
	--- for _, stack in pairs(inventory) do -- needs pairs!
	for i = 1, #items do
		stack = items[i]
		obj = stack.object
		objType = obj.objectType
		if objType then
			if objType == CLOTH_TYPE then
				objSlot = obj.slot
				if objSlot then
					if objSlot == RING_SLOT then
						if ringCount < maxRingSlots then
							checkEquipment(npcRef, obj, false)
							ringCount = ringCount + 1
						else
							ringFound = true
						end
					elseif objSlot == AMULET_SLOT then
						if not amuletFound then
							checkEquipment(npcRef, obj, false)
							amuletFound = true
						end
					end -- if (objSlot ==
					if amuletFound and ringFound then
						return
					end
				end -- if objSlot
			end-- if objType ==
		end -- if objType
	end -- for _, stack
end

local tes3_actorType_creature = tes3.actorType.creature -- 0
local tes3_actorType_npc = tes3.actorType.npc -- 1
local tes3_actorType_player = tes3.actorType.player -- 2

local function validNPC(ref)
	if not ref then
		assert(ref)
		return false
	end
	if not ref.sceneNode then
		---assert(ref.sceneNode) it may happen if something else is bugged
		return false
	end
	if displayLevel == 0 then
		return false
	end
	if ref.disabled then
		return false
	end
	if ref.deleted then
		return false
	end
	local mobile = ref.mobile
	if not mobile then
		---dm("mobile = %s id = %s", mobile, ref.id)
		---assert(mobile) -- no assert as it may happen e.g. agronian guy the Tahriel falling one
		return false
	end
	local obj = ref.baseObject
	local race = obj.race
	if not race then
		return false
	end
	if not race.isPlayable then
		return false -- not a playable race
	end
	local actorType = mobile.actorType -- 0 = creature, 1 = NPC, 2 = player
	--[[
	if not actorType then
		assert(actorType) ---dm("not actorType")
		return false
	end
	]]
	if actorType == tes3_actorType_creature then
		return false
	elseif actorType == tes3_actorType_npc then
		if displayLevel < 2 then
			return false
		end
	else -- if actorType == tes3_actorType_player then
		if logLevel >= 3 then
			dm("validNPC == player %s %s", ref.id, obj.name)
		end
		return true -- player
	end
	if logLevel >= 3 then
		dm("validNPC %s %s", ref.id, obj.name)
	end
	return true
end

local function refreshNPC(ref)
	if not validNPC(ref) then
		return
	end
	local equippedAmuletCount, equippedRingCount = initEquipment(ref)
	if equippedAmuletCount > 0 then
		if equippedRingCount >= maxRingSlots then
			return
		end
	end
	initNPCClothing(ref, equippedAmuletCount, equippedRingCount)
end

local function mobileActivated(e)
	local ref = e.reference
	--[[if ref == player then
		assert(false, "Vanity: mobileActivated() e.reference = player")
		return
	end]]
	refreshNPC(ref)
end

local function equippedOrUnequipped(e, itemUnequipped)
	local ref = e.reference
	if not validNPC(ref) then
		return
	end
	checkEquipment(ref, e.item, itemUnequipped)
end

local function equipped(e)
	equippedOrUnequipped(e, false)
end

local function unequipped(e)
	equippedOrUnequipped(e, true)
end

local function initVars()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	firstPersonNode = tes3.player1stPerson.sceneNode
end

local function initVarsAndEquipment()
	initVars()
	initEquipment(player)
end

--[[
local function cleanOldPlayerData()
	if not player then
		return
	end
	if not player.data then
		return
	end
	if not player.data.ab01Vanity then
		return
	end
	player.data.ab01Vanity = nil
end
]]

local debugOnce
local function loaded()
	---cleanVisualCache()
	initVarsAndEquipment()
	debugOnce = false
	---cleanOldPlayerData()
end

-- set in modConfigReady
local sYes
local sNo

local function debugPressed()
	local msg = string.format(
"%s test helper:\nReset equipped amulet and rings and add one of each different looking\namulets, rings, gloves, gauntlets, shirts, cuirasses, robes to player?"
, modPrefix)

	local function giveDistinctItems(npcRef)
		local objSlot, mesh, icon, isGlove, isGauntlet, isPretty
		local clothMeshes = {}
		local armorMeshes = {}
		local prettyCount = 0
		local c
		-- add 1 copy of different looking available rings/amulets/robes/shirts/gloves to player
		for obj in tes3.iterateObjects(CLOTH_TYPE) do
			objSlot = obj.slot
			if objSlot then
				isGlove = (objSlot == LEFT_GLOVE_SLOT)
				or (objSlot == RIGHT_GLOVE_SLOT)

				isPretty = (objSlot == AMULET_SLOT)
				or (objSlot == RING_SLOT)

				if isGlove
				or (objSlot == AMULET_SLOT)
				or (objSlot == RING_SLOT)
				or (objSlot == ROBE_SLOT)
				or (objSlot == SHIRT_SLOT) then
					mesh = obj.mesh
					if mesh then
						-- skip items with no icon, they usually are fake
						icon = obj.icon
						if icon then
							if string.len(icon) > 0 then
								mesh = mesh:lower()
								if isGlove
								or (not clothMeshes[mesh]) then
									if isPretty then
										prettyCount = prettyCount + 1
									end
									clothMeshes[mesh] = true
									---c = mwscript.getItemCount({ reference = npcRef, item = obj })
									c = tes3.getItemCount({ reference = npcRef, item = obj })
									if c == 0 then
										---mwscript.addItem({ reference = npcRef, item = obj, count = 1 })
										tes3.addItem({ reference = npcRef, item = obj, count = 1, playSound = false, updateGUI = false })
									end
								end
							end
						end
					end
				end
			end
		end
		mwse.log("%s: Found %s distinct amulets and rings", modPrefix, prettyCount)

		-- add 1 copy of different looking available gauntlets/cuirasses to npc
		for obj in tes3.iterateObjects(ARMO_TYPE) do
			objSlot = obj.slot
			if objSlot then
				isGauntlet = (objSlot == LEFT_GAUNTLET_SLOT)
						or (objSlot == RIGHT_GAUNTLET_SLOT)
				if isGauntlet
				or (objSlot == CUIRASS_SLOT) then
					mesh = obj.mesh
					if mesh then
						icon = obj.icon
						if icon then
							if string.len(icon) > 0 then
								mesh = mesh:lower()
								if isGauntlet
								or (not armorMeshes[mesh]) then
									armorMeshes[mesh] = true
									---c = mwscript.getItemCount({ reference = npcRef, item = obj })
									c = tes3.getItemCount({ reference = npcRef, item = obj })
									if c <= 0 then
										---mwscript.addItem({ reference = npcRef, item = obj, count = 1 })
										tes3.addItem({ reference = npcRef, item = obj, count = 1, playSound = false, updateGUI = false })
									end
								end
							end
						end
					end
				end
			end
		end
		if npcRef == player then
			tes3.updateInventoryGUI({reference = npcRef})
		end
	end

	local function unequipAmuletAndRings(mobile)
		mobile:unequip({clothingSlot = AMULET_SLOT})
		local j = 1
		local m = 2
		if mobile.actorType then
			if mobile.actorType == tes3_actorType_player then
				m = maxRingSlots
			end
		end
		while j <= m do
			mobile:unequip({clothingSlot = RING_SLOT})
			j = j + 1
		end
	end

	tes3.messageBox({
		message = msg,
		buttons = { sYes, sNo },
		callback = function(e)
			if (e.button == 0) then
				debugOnce = true
				tes3.messageBox("%s: resetting amulet and rings, adding items...", modPrefix)
				unequipAmuletAndRings(mobilePlayer)
				giveDistinctItems(player)
			end
		end
	})
end


local function onDebugKeysPressed(e)
	if logLevel > 0 then
		if e.isAltDown and e.isShiftDown and (not debugOnce) then
			debugPressed()
		end
	end
end

local function ab01vntyPT1()
	initVarsAndEquipment()
end

local function afterDestroyMenuRaceSex()
	---mwse.log('%s: afterDestroyMenuRaceSex()', modPrefix)
	timer.start({ duration = 1, callback = 'ab01vntyPT1'}) -- needs a delay!
end

local function uiMenuRaceSexActivated(e)
	if e.newlyCreated then
		e.element:registerAfter('destroy', afterDestroyMenuRaceSex)
	end
end

--[[
event order test:
1 modConfigReady
2 initialized
3 mobileActivated
--]]
local function initialized()
	event.register('loaded', loaded)
	event.register('equipped', equipped)
	event.register('unequipped', unequipped)
	event.register('keyDown', onDebugKeysPressed, {filter=tes3.scanCode.d}) -- Shift+Alt+D
	event.register('mobileActivated', mobileActivated)
	timer.register('ab01vntyPT1', ab01vntyPT1) -- using a persistent timer
	event.register('uiActivated', uiMenuRaceSexActivated, {filter = 'MenuRaceSex'})
end
event.register('initialized', initialized)

local resetConfig = false

local function modConfigReady()

	sYes = tes3.findGMST(tes3.gmst.sYes).value
	sNo = tes3.findGMST(tes3.gmst.sNo).value

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		if resetConfig then
			resetConfig = false
			config = defaultConfig
		end
		if not tes3.onMainMenu() then
			local ref = tes3.player
			if ref then
				---setConfigAmuletsRings(ref)
				initEquipment(ref)
			end
		end
		displayLevel = config.displayLevel
		logLevel = config.logLevel
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Info",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.4
			self.elements.sideToSideBlock.children[2].widthProportional = 0.6
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo{text = ""}

	local controls = preferences:createCategory{label="Vanity - Visible equipped amulets & rings\n"}

	controls:createDropdown{
		label = "Amulet visibility level:",
		options = {
			{ label = "0. Not visible", value = 0 },
			{ label = "1. Bare Chest", value = 1 },
			{ label = "2. Shirt", value = 2 },
			{ label = "3. Cuirass", value = 3 },
			{ label = "4. Robe", value = 4 },
		},
		variable = createConfigVariable("viewAmuletLevel"),
		description = [[
Amulet visibility over selected item (and the lesser level ones). Default "4. Robe".
e.g. option "3. Cuirass" will make amulet visible on cuirass/shirt/bare chest but not on robe.
Note that positions are optimized for bare chest as shape and size of shirt, cuirass and robe may vary much more.
]]
	}
	controls:createDropdown{
		label = "Rings visibility level:",
		options = {
			{ label = "0. Not visible", value = 0 },
			{ label = "1. Bare Hands", value = 1 },
			{ label = "2. Gloves", value = 2 },
			{ label = "3. Gauntlets", value = 3 },
		},
		variable = createConfigVariable("viewRingsLevel"),
		description = [[
Default: "3. Gauntlets".
Rings visibility over selected item (and the lesser level ones)
e.g. option "2. Gloves" will make rings visible on gloves/bare hands but not on gauntlets.
Note that positions are optimized for bare hands as shape and size of glove and gauntlet may vary much more.
]]
	}

	controls:createDropdown{
		label = "Show amulets and rings:",
		options = {
			{ label = "0. Disabled", value = 0 },
			{ label = "1. Equipped by Player", value = 1 },
			{ label = "2. Equipped by NPCs", value = 2 },
			{ label = "3. In NPC's inventory", value = 3 },
		},
		variable = createConfigVariable("displayLevel"),
		description = [[
Default "3. In NPC's inventory" option will display equipped/in inventory amulets and rings on any playable race NPC.
"0. Disabled" is mostly to temporarily disable the mod effects.
Disabling "2. Equipped by NPCs" or "3. In NPC's inventory" usually will refresh the
amulet and rings graphics on currently loaded NPCs on next cell load.
Only equipped amulet and rings will be visible on player (else it would become confusing to understand
what items you have currently equipped), while NPCs can show also unequipped amulet and rings.
This is because NPCs may not always equip items, and items equipped by NPCs are no more accessible
from NPCs inventory/barter menus so it's better to avoid messing with how default game/other mods equip them.
]]
	}

	local onUseRingExtraSlot = tes3.hasCodePatchFeature(tes3.codePatchFeature.onUseRingExtraSlot)
	local s = "%s: modConfigReady, Morrowind Code Patch option to enable 1 extra on-use ring slot "
	if onUseRingExtraSlot then
		maxRingSlots = 3
		mwse.log(s .. 'detected', modPrefix)
	else
		maxRingSlots = 2
		if config.maxVisibleRings > maxRingSlots then
			config.maxVisibleRings = maxRingSlots
		end
		mwse.log(s .. 'NOT detected', modPrefix)
	end
	controls:createSlider{
		label = "Max. number of visible rings",
		variable = createConfigVariable("maxVisibleRings")
		,min = 1, max = maxRingSlots, step = 1, jump = 1,
		description = [[
Max number of rings visible at the same time. Default: 2 or 3.
If you have the Morrowind Code Patch option to enable 1 extra ring slot
for enchanted-on-use rings, you should increase this value to 3.
]]
	}

	controls:createSlider{
		label = "Amulet forward offset",
		description = "Amulet position forward offset (X 0.03), default: 0.",
		variable = createConfigVariable("amuletForwardOffset")
		,min = -100, max = 100, step = 1, jump = 5
	}
	controls:createSlider{
		label = "Amulet side offset",
		description = "Amulet position side offset (X 0.03), default: 0.",
		variable = createConfigVariable("amuletSideOffset")
		,min = -100, max = 100, step = 1, jump = 5
	}
	controls:createSlider{
		label = "Amulet vertical offset",
		description = "Amulet position vertical offset (X 0.03), default: 0.",
		variable = createConfigVariable("amuletVerticalOffset")
		,min = -100, max = 100, step = 1, jump = 5
	}
	controls:createSlider{
		label = "Amulet scale (%)",
		description = "Default: 100%",
		variable = createConfigVariable("amuletScale")
		,min = 50, max = 150, step = 1, jump = 5
	}
	controls:createSlider{
		label = "Ring forward offset",
		description = "Ring position forward offset (X 0.0075), default: 0.",
		variable = createConfigVariable("ringForwardOffset")
		,min = -100, max = 100, step = 1, jump = 5
	}
	controls:createSlider{
		label = "Ring side offset",
		description = "Ring position side offset (X 0.0075), default: 0.",
		variable = createConfigVariable("ringSideOffset")
		,min = -100, max = 100, step = 1, jump = 5
	}
	controls:createSlider{
		label = "Ring scale (%)",
		description = "Default: 100%",
		variable = createConfigVariable("ringScale")
		,min = 75, max = 125, step = 1, jump = 5
	}

	controls:createButton{
		label = "Update amulet and rings position according to sliders",
		description = [[
Setting Menu Transparency from in Game Options may allow to see the changes
to amulet and rings display on player while working in this MCM panel.
]],
		buttonText = "Update view",
		callback = function()
			local ref = tes3.player
			if ref then
				initEquipment(ref)
			end
		end
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Minimum", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
		},
		variable = createConfigVariable("logLevel"),
		description = [[
Default: 0. Minimum.
If set higher than 0, pressing Shift+Alt+D will show
a debug testing option allowing you to reset amulet and rings visibility and get one
of each different looking amulets, rings, gloves, gauntlets, shirts, cuirasses, robes.
Warning: if your loading list is adding tons of these items, this will take some time and may appear to freeze your game, please wait!
]]
	}

--[[
	controls:createButton{
		label = "WARNING, it will reset saved settings to installation default on exit!",
		buttonText = "Reset configuration",
		callback = function()
			resetConfig = true
		end,
	}
--]]

	controls:createYesNoButton{
		label = "In-game debug messages",
		description = "Default: No. Usually not needed.",
		variable = createConfigVariable("debugMessages")
	}

	local mcpDesc = "Morrowind Code Patch + Beta update option to enable 1 extra on-use ring slot highly suggested to enable one more shiny."
	local function getNexusModLink(decimalId)
		return string.format("start https://www.nexusmods.com/morrowind/mods/%s", decimalId)
	end
	controls:createHyperlink{
		text = "Morrowind Code Patch",
		exec = getNexusModLink(19510),
		description = mcpDesc
	}
	controls:createHyperlink{
		text = "Morrowind Code Patch Beta Update",
		exec = getNexusModLink(26348),
		description = mcpDesc
	}
	controls:createHyperlink{
		text = "MGE-XE",
		exec = getNexusModLink(41102),
	}
	controls:createHyperlink{
		text = "Latest MWSE-Lua development build",
		exec = 'start https://nullcascade.com/mwse/mwse-dev.zip'
	}
	controls:createHyperlink{
		text = "Better Bodies",
		exec = getNexusModLink(42395),
		description = [[
Amulets and rings positioning is tweaked/tested using Better Bodies (and optimized for Breton female race),
using vanilla/other body replacers may not work the same.
]]
	}
	controls:createHyperlink{
		text = "New Beast Bodies",
		exec = 'start http://mw.modhistory.com/download-10-11364',
		description = [[
Amulets and rings positioning is tweaked/tested using New Beast Bodies,
using vanilla/other body replacers may not work the same.
]]
	}
	controls:createHyperlink{
		text = "Assetless No Glow",
		exec = getNexusModLink(47925),
		description = [[
If you install Assetless No Glow and delete any Textures/magicitem/caustXX.dds
you will still have no-glow armors but keep the pretty shiny glow on amulets and rings!
]]
	}
	controls:createHyperlink{
		text = "abot's Morrowind mods on Nexus",
		exec = 'start https://www.nexusmods.com/users/38047?tab=user+files&BH=0',
	}
	controls:createHyperlink{
		text = "abot's Morrowind site",
		exec = 'start https://abitoftaste.altervista.org/morrowind/',
	}

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)

--[[
Try and fix te3.loadAnimation currently nuking player visual attachments.
Should avoid mods using it (e.g. Double CHIM, 4NM - Total Gameplay Overhaul,
Sails and Sales, The Art of Alchemy, Dwemer Cycle...) disabling visual
attachments added by Vanity.
]]
local oldLoadAnimation = tes3.loadAnimation -- store original function
local newLoadAnimation = function(paramsTable)
	oldLoadAnimation(paramsTable) -- execute old tes3.loadAnimation
	local ref = paramsTable.reference
	if not ref then
		return
	end
	if ref == tes3.player1stPerson then
		firstPersonNode = tes3.player1stPerson.sceneNode -- important to refresh this too!
		ref = tes3.player
	elseif ref.reference then -- in case ref is a mobile
		ref = ref.reference
	end
	---mwse.log('refreshNPC("%s")', ref.id)
	refreshNPC(ref)
end
tes3.loadAnimation = newLoadAnimation