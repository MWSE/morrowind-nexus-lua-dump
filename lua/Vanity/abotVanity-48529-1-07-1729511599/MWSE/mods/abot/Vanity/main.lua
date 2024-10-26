---@diagnostic disable: undefined-field, assign-type-mismatch
--@diagnostic disable: cast-local-type, assign-type-mismatch, undefined-field
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
amuletSideOffset = 18, -- Amulet position side offset (X 0.03)
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
local ringSlotNames = {}
ringSlotNames[1] = 'Bip01 L Finger1'
ringSlotNames[2] = 'Bip01 R Finger1'
ringSlotNames[3] = 'Bip01 L Finger2'
ringSlotNames[4] = 'Bip01 L Finger3' -- bah. 1st person view has different finger nodes, go figure

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
assert(config)
if config.debugLevel then  -- update legacy
	config.logLevel = config.debugLevel
	config.debugLevel = nil
end

local viewAmuletLevel, viewRingsLevel, maxVisibleRings, displayLevel
local amuletForwardOffset, amuletSideOffset, amuletVerticalOffset, amuletScale
local ringForwardOffset, ringSideOffset, ringScale
local debugMessages
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

local function dm(str, ...)
	if not logLevel1 then
		return
	end
	local s = modPrefix..': '..tostring(str):format(...)
	print(s)
	if config.debugMessages then
		tes3ui.showNotifyMenu(s)
	end
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

-- set in loaded()
local player
local mobilePlayer
local firstPersonNode

local tes3_objectType_armor = tes3.objectType.armor
local tes3_objectType_clothing = tes3.objectType.clothing
local tes3_objectType_npc = tes3.objectType.npc

local tes3_clothingSlot_amulet = tes3.clothingSlot.amulet
local tes3_clothingSlot_ring = tes3.clothingSlot.ring
local tes3_clothingSlot_robe = tes3.clothingSlot.robe
local tes3_clothingSlot_shirt = tes3.clothingSlot.shirt
local tes3_clothingSlot_leftGlove = tes3.clothingSlot.leftGlove
local tes3_clothingSlot_rightGlove = tes3.clothingSlot.rightGlove

local tes3_armorSlot_cuirass = tes3.armorSlot.cuirass
local tes3_armorSlot_leftGauntlet = tes3.armorSlot.leftGauntlet
local tes3_armorSlot_rightGauntlet = tes3.armorSlot.rightGauntlet

local ab01node = 'ab01vntyNode'

--[[
local visualsCache = {} -- visuals cache, cleared in loaded()
local visualsCacheMaxSize = 50

local maxUsedCache = 0

local function cleanVisualCache()
	if logLevel2 then
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
				if logLevel2 then
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
		visual.name = ab01node
	end
	return visual
end
]]

local function getVisual(mesh)
	local visual = tes3.loadMesh(mesh)
	if visual then
		visual = visual:clone()
		visual:clearTransforms()
		visual.name = ab01node
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
	local child = attachNode:getObjectByName(ab01node)
	if child then
		if logLevel3 then
			dm("clearPreviousVisual: attachNode:detachChild(attachNode = %s, child = %s)", attachNode.name, child.name)
		end
		attachNode:detachChild(child)
	end
end

local function updateRingNode(sceneNode, item, ringSlotNum, scale, dy, dz)
	local slotName = ringSlotNames[ringSlotNum]
	if (ringSlotNum == 3)
	and (sceneNode == firstPersonNode) then
		slotName = ringSlotNames[4] -- 1st person view has different finger nodes
	end
	---assert(slotName)
	local attachNode = sceneNode:getObjectByName(slotName)
	if not attachNode then
		return
	end
	clearPreviousVisual(attachNode)
	if not item then
		if logLevel4 then
			dm("updateRingNode cleared sceneNode = %s, attachNode = %s, slot = %s",
				sceneNode.name, attachNode.name, ringSlotNum)
		end
		updateNodes(sceneNode)
		return
	end

	if logLevel3 then
		dm("updateRingNode drawn: item = %s, sceneNode = %s, attachNode = %s, slot = %s",
			item.id, sceneNode.name, attachNode.name, ringSlotNum)
	end
	local mesh = item.mesh
	if not mesh then
		return
	end
	mesh = string.lower(mesh)

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

-- 1 = bare chested, 2 = shirt, 3 = cuirass, 4 = robe
local function getEquippedChestLevel(npcRef)
	if tes3.getEquippedItem({actor = npcRef, objectType = tes3_objectType_clothing,
			slot = tes3_clothingSlot_robe}) then
		return 4
	end
	if tes3.getEquippedItem({actor = npcRef, objectType = tes3_objectType_armor,
			slot = tes3_armorSlot_cuirass}) then
		return 3
	end
	if tes3.getEquippedItem({actor = npcRef, objectType = tes3_objectType_clothing,
			slot = tes3_clothingSlot_shirt}) then
		return 2
	end
	return 1
end

local function getEquippedLeftHandLevel(npcRef) -- 1 = bare hands, 2 = gloves, 3 = gauntlets
	if tes3.getEquippedItem({actor = npcRef, objectType = tes3_objectType_armor,
			slot = tes3_armorSlot_leftGauntlet}) then
		return 3
	end
	if tes3.getEquippedItem({actor = npcRef, objectType = tes3_objectType_clothing,
			slot = tes3_clothingSlot_leftGlove}) then
		return 2
	end
	return 1
end

local function getEquippedRightHandLevel(npcRef) -- 1 = bare hands, 2 = gloves, 3 = gauntlets
	if tes3.getEquippedItem({actor = npcRef, objectType = tes3_objectType_armor,
			slot = tes3_armorSlot_rightGauntlet}) then
		return 3
	end
	if tes3.getEquippedItem({actor = npcRef, objectType = tes3_objectType_clothing,
			slot = tes3_clothingSlot_rightGlove }) then
		return 2
	end
	return 1
end

-- stored onSave(), restored on loaded()
local amuletsOffset = {}
local ringsOffset = {}

local function getMeshKey(item)
	-- e.g. 'foo\bar\mycloth'
	return string.lower(string.sub(item.mesh, 1, -5))
end

local function updateRingVisual(npcRef, item, ringSlotNum, changed)
	local sceneNode = npcRef.sceneNode
	local level
	if ringSlotNum == 2 then
		level = getEquippedRightHandLevel(npcRef)
	else
		level = getEquippedLeftHandLevel(npcRef)
	end
	local lscale = 1
	if level == 3 then
		lscale = 1.27
	elseif level == 2 then
		lscale = 1.18
	end

	local yOffset = -0.0075 * ringForwardOffset
	local zOffset = 0.0075 * ringSideOffset
	local scale = lscale * ringScale * 0.01
	
	if item.mesh then
		local key = getMeshKey(item)
		if changed then
			ringsOffset[key] = {y = ringForwardOffset, z = ringSideOffset, s = ringScale}
			if logLevel2 then
				mwse.log([[%s: updateRingVisual("%s", "%s", %s, %s)
ringsOffset["%s"] = {y = %s, z = %s, s = %s}]],
					modPrefix, npcRef.id, item.id, ringSlotNum,
					changed, key, ringForwardOffset, ringSideOffset, ringScale)
			end
		else
			local offset = ringsOffset[key]
			if offset then
				yOffset = -0.0075 * offset.y
				zOffset = 0.0075 * offset.z
				scale = lscale * offset.s * 0.01
				if logLevel3 then
					mwse.log([[%s: updateRingVisual("%s", "%s", %s, %s)
ringsOffset["%s"] = {y = %s, z = %s, s = %s}]],
						modPrefix, npcRef.id, item.id, ringSlotNum,
						changed, key, yOffset, zOffset, scale)
				end
			end
		end
	end
	updateRingNode(sceneNode, item, ringSlotNum, scale, yOffset, zOffset)
	if npcRef == player then
		updateRingNode(firstPersonNode, item, ringSlotNum, scale * 1.09, yOffset, zOffset)
	end
end

-- note: clears amulet view when item is nil
local function updateAmuletNode(sceneNode, item, scale, xOffset, yOffset, zOffset)
	---tes3ui.showNotifyMenu("item = %s", item.id)
	local attachNode = sceneNode:getObjectByName('Bip01 Neck')
	if attachNode then
		if logLevel3 then
			if item then
				dm('updateAmuletNode sceneNode = "%s", item = "%s" drawn', sceneNode.name, item.id)
			else
				dm('updateAmuletNode sceneNode = "%s" cleared', sceneNode.name)
			end
		end
	else
		return
	end
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

local function updateAmuletVisual(npcRef, item, changed)
	local sceneNode = npcRef.sceneNode
	local xOffset = (amuletVerticalOffset * 0.03) + 0.6
	local yOffset = (amuletForwardOffset * 0.03) - 0.1
	local zOffset = amuletSideOffset * 0.03
	local scale = amuletScale * 0.01
	if item
	and item.mesh then
		local key = getMeshKey(item)

		local ei = tes3.getEquippedItem({actor = npcRef,
			objectType = tes3_objectType_clothing, slot = tes3_clothingSlot_robe})
		if ei then
			key = getMeshKey(ei.object) .. '|' .. key
		else
			ei = tes3.getEquippedItem({actor = npcRef,
				objectType = tes3_objectType_armor, slot = tes3_armorSlot_cuirass})
			if ei then
				key = getMeshKey(ei.object) .. '|' .. key
			end
		end
		if changed then
			amuletsOffset[key] = {x = amuletVerticalOffset, y = amuletForwardOffset,
				z = amuletSideOffset, s = amuletScale}
			if logLevel2 then
				mwse.log([[%s: updateAmuletVisual(npc = "%s" "%s", item = "%s" changed = %s)
amuletsOffset["%s"] = {x = %s, y = %s, z = %s, s = %s}]],
					modPrefix, npcRef.id, npcRef.object.name, item.id,
					changed, key, amuletVerticalOffset, amuletForwardOffset, amuletSideOffset, amuletScale)
			end
		else
			local offset = amuletsOffset[key]
			if offset then
				xOffset = (offset.x * 0.03) + 0.6
				yOffset = (offset.y * 0.03) - 0.1
				zOffset = offset.z * 0.03
				scale = offset.s * 0.01
				if logLevel3 then
					mwse.log([[%s: updateAmuletVisual(npc = "%s" "%s", item = "%s" changed = %s)
amuletsOffset["%s"] = {x = %s, y = %s, z = %s, s = %s}]],
						modPrefix, npcRef.id, npcRef.object.name, item.id,
						changed, key, xOffset, yOffset, zOffset, scale)
				end
			end
		end
	end
	-- note: if item is nil visuals are cleared
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
	return viewRingsLevel >= getEquippedLeftHandLevel(npcRef)
end

local function rightRingsAllowed(npcRef)
	return viewRingsLevel >= getEquippedRightHandLevel(npcRef)
end

local function checkRing(npcRef, stack, slot, skipCleaning, leftAllowed, rightAllowed)
-- output: 0 = not valid, 1 = ring slot cleaned, 2 = ring slot drawn
	local obj = stack.object
	if not obj then
		return 0
	end
	local objType = obj.objectType
	if not objType then
		return 0
	end
	if not (objType == tes3_objectType_clothing) then
		return 0
	end
	local objSlot = obj.slot
	if not objSlot then
		return 0
	end
	if not (objSlot == tes3_clothingSlot_ring) then
		return 0
	end
	if not obj.mesh then
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
	updateRingVisual(npcRef, obj, slot)
	return 2
end

local function checkRings(npcRef)
	if (displayLevel < 2)
	and (not (npcRef == player)) then
		return
	end
	local maxSlot = maxVisibleRings
	local usedRingSlots = {}
	local leftAllowed = leftRingsAllowed(npcRef)
	local rightAllowed = rightRingsAllowed(npcRef)
	local result
	local skipCleaning = false
	local slot = 1
	-- check for equipped rings first
	for _, stack in pairs(npcRef.object.equipment) do -- pairs, better safe than sorry
		if stack
		and (not usedRingSlots[slot]) then
			result = checkRing(npcRef, stack, slot, skipCleaning, leftAllowed, rightAllowed)
			if result == 2 then
				usedRingSlots[slot] = result
				if logLevel2 then
					dm('checkRings(npcRef = "%s" "%s") "%s" "%s" slot %s', npcRef.id, npcRef.object.name, stack.object.id, stack.object.name, slot)
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
	--- for _, stack in pairs(npcRef.object.inventory) do -- needs pairs!
	for i = 1, #items do
		if not usedRingSlots[slot] then
			local stack = items[i]
			result = checkRing(npcRef, stack, slot, skipCleaning, leftAllowed, rightAllowed)
			if result == 2 then
				usedRingSlots[slot] = result
				if logLevel2 then
					dm('checkRings(npcRef = "%s" "%s") "%s" "%s" slot %s', npcRef.id, npcRef.object.name, stack.object.id, stack.object.name, slot)
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
		return false
	end
	local objType = obj.objectType
	if not objType then
		return false
	end
	if not (objType == tes3_objectType_clothing) then
		return false
	end
	local objSlot = obj.slot
	if not objSlot then
		return false
	end
	if not (objSlot == tes3_clothingSlot_amulet) then
		return false
	end
	if not obj.mesh then
		return false
	end
	updateAmuletVisual(npcRef, obj)
	return true
end

local function updateAmulet(npcRef, changed)
	if (displayLevel < 2)
	and (not (npcRef == player)) then
		return
	end
	-- check for equipped amulet first
	local st = tes3.getEquippedItem({ actor = npcRef, objectType = tes3_objectType_clothing,
			slot = tes3_clothingSlot_amulet })
	local obj
	if st then
		obj = st.object
		if obj
		and (not obj.mesh) then
			obj = nil
		end
	end
	if obj
	and logLevel2 then
		dm('updateAmulet(npcRef = "%s" "%s") "%s" "%s" amulet changed = %s',
			npcRef.id, npcRef.object.name, obj.id, obj.name, changed)
	end
	updateAmuletVisual(npcRef, obj, changed)
	if obj then
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
	for i = 1, #items do
		local stack = items[i]
		if checkAmuletStack(npcRef, stack) then
			if logLevel2 then
				dm("updateAmulet(npcRef = %s %s) %s %s amulet",
					npcRef.id, npcRef.object.name, stack.object.id, stack.object.name)
			end
			return
		end
	end
end

local function updateFromConfig()
	viewAmuletLevel = config.viewAmuletLevel
	viewRingsLevel = config.viewRingsLevel
	maxVisibleRings = config.maxVisibleRings
	displayLevel = config.displayLevel

	local update = false

	if amuletForwardOffset
	and ( not (amuletForwardOffset == config.amuletForwardOffset) ) then
		update = true
	end
	amuletForwardOffset = config.amuletForwardOffset

	if amuletSideOffset
	and ( not (amuletSideOffset == config.amuletSideOffset) ) then
		update = true
	end
	amuletSideOffset = config.amuletSideOffset

	if amuletVerticalOffset
	and ( not (amuletVerticalOffset == config.amuletVerticalOffset) ) then
		update = true
	end
	amuletVerticalOffset = config.amuletVerticalOffset

	if amuletScale
	and ( not (amuletScale == config.amuletScale) ) then
		update = true
	end
	amuletScale = config.amuletScale

	if update
	and player then
		updateAmulet(player, true)
	end

	update = false

	if ringForwardOffset
	and ( not (ringForwardOffset == config.ringForwardOffset) ) then
		update = true
	end
	ringForwardOffset = config.ringForwardOffset

	if ringSideOffset
	and ( not (ringSideOffset == config.ringSideOffset) ) then
		update = true
	end
	ringSideOffset = config.ringSideOffset

	if ringScale
	and ( not (ringScale == config.ringScale) ) then
		update = true
	end
	ringScale = config.ringScale

	if update
	and player then
		checkRings(player)
	end

	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
end
updateFromConfig()

local function amuletAllowed(npcRef)
	return viewAmuletLevel >= getEquippedChestLevel(npcRef)
end

local function checkAmulet(npcRef)
	if amuletAllowed(npcRef) then
		updateAmulet(npcRef)
	else
		updateAmuletVisual(npcRef)
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
	if not (objType == tes3_objectType_npc) then
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

	if itemType == tes3_objectType_clothing then
		if (slot == tes3_clothingSlot_robe)
		or (slot == tes3_clothingSlot_shirt)
		or (slot == tes3_clothingSlot_amulet) then
			checkAmulet(npcRef)
		elseif (slot == tes3_clothingSlot_ring) then
			if itemUnequipped then
				for ringSlotNum = 1, maxRingSlots do
					clearVisibleRing(npcRef, ringSlotNum)
				end
			end
			checkRings(npcRef)
		elseif (slot == tes3_clothingSlot_leftGlove)
			or (slot == tes3_clothingSlot_rightGlove) then
			checkRings(npcRef)
		end
		return
	end

	if itemType == tes3_objectType_armor then
		if (slot == tes3_armorSlot_cuirass) then
			checkAmulet(npcRef)
		elseif (slot == tes3_armorSlot_leftGauntlet)
			or (slot == tes3_armorSlot_rightGauntlet) then
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
	local amuletCount = 0
	local ringCount = 0
	for _, stack in pairs(npcRef.object.equipment) do
		if stack then
			local obj = stack.object
			local objType = obj.objectType
			if objType
			and (objType == tes3_objectType_clothing) then
				local objSlot = obj.slot
				if objSlot then
					if (objSlot == tes3_clothingSlot_ring) then
						ringCount = ringCount + 1
						checkEquipment(npcRef, obj, false)
					elseif (objSlot == tes3_clothingSlot_amulet) then
						amuletCount = amuletCount + 1
						checkEquipment(npcRef, obj, false)
					end
				end -- if (objSlot
			end -- if objType
		end
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

	local amuletFound = equippedAmuletCount > 0
	local ringFound = equippedRingsCount >= maxRingSlots
	local ringCount = equippedRingsCount
	if logLevel3 then
		dm("initNPCClothing(npc = %s %s amulets = %s rings = %s)",
			npcRef.id, npcRef.object.name, equippedAmuletCount, equippedRingsCount)
	end
	local items = inventory.items
	for i = 1, #items do
		local stack = items[i]
		local obj = stack.object
		local objType = obj.objectType
		if objType
		and (objType == tes3_objectType_clothing) then
			local objSlot = obj.slot
			if objSlot then
				if objSlot == tes3_clothingSlot_ring then
					if ringCount < maxRingSlots then
						checkEquipment(npcRef, obj, false)
						ringCount = ringCount + 1
					else
						ringFound = true
					end
				elseif objSlot == tes3_clothingSlot_amulet then
					if not amuletFound then
						checkEquipment(npcRef, obj, false)
						amuletFound = true
					end
				end -- if (objSlot ==
				if amuletFound and ringFound then
					return
				end
			end -- if objSlot
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
		if logLevel4 then
			dm("validNPC == player %s %s", ref.id, obj.name)
		end
		return true -- player
	end
	if logLevel4 then
		dm("validNPC %s %s", ref.id, obj.name)
	end
	return true
end

local function refreshNPC(ref)
	if not validNPC(ref) then
		return
	end
	local equippedAmuletCount, equippedRingCount = initEquipment(ref)
	if (equippedAmuletCount > 0)
	and (equippedRingCount >= maxRingSlots) then
		return
	end
	initNPCClothing(ref, equippedAmuletCount, equippedRingCount)
end

local function mobileActivated(e)
	--[[
	local ref = e.reference
	if ref == tes3.player then
		assert(false, "Vanity: mobileActivated() e.reference = player")
		return
	end
	]]
	refreshNPC(e.reference)
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

-- set in modConfigReady
local sYes
local sNo

local debugOnce

local function debugPressed()
	local msg = string.format([[%s test helper:
Reset equipped amulet and rings and add one of each different looking
amulets, rings, gloves, gauntlets, shirts, cuirasses, robes to player?]], modPrefix)

	local function giveDistinctItems(npcRef)
		local clothMeshes = {}
		local armorMeshes = {}
		local prettyCount = 0
		local c
		-- add 1 copy of different looking available rings/amulets/robes/shirts/gloves to player
		for obj in tes3.iterateObjects(tes3_objectType_clothing) do
			local objSlot = obj.slot
			if objSlot then
				local isGlove = (objSlot == tes3_clothingSlot_leftGlove)
					or (objSlot == tes3_clothingSlot_rightGlove)

				local isJewel = (objSlot == tes3_clothingSlot_amulet)
					or (objSlot == tes3_clothingSlot_ring)

				if isGlove
				or isJewel
				or (objSlot == tes3_clothingSlot_robe)
				or (objSlot == tes3_clothingSlot_shirt) then
					local mesh = obj.mesh
					if mesh then
						-- skip items with no icon, they usually are fake
						local icon = obj.icon
						if icon
						and (string.len(icon) > 0) then
							mesh = string.lower(mesh)
							if isGlove
							or (not clothMeshes[mesh]) then
								if isJewel then
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
		mwse.log("%s: Found %s distinct amulets and rings", modPrefix, prettyCount)

		-- add 1 copy of different looking available gauntlets/cuirasses to npc
		for obj in tes3.iterateObjects(tes3_objectType_armor) do
			local objSlot = obj.slot
			if objSlot then
				local isGauntlet = (objSlot == tes3_armorSlot_leftGauntlet)
						or (objSlot == tes3_armorSlot_rightGauntlet)
				if isGauntlet
				or (objSlot == tes3_armorSlot_cuirass) then
					local mesh = obj.mesh
					if mesh then
						local icon = obj.icon
						if icon
						and (string.len(icon) > 0) then
							mesh = mesh:lower()
							if isGauntlet
							or (not armorMeshes[mesh]) then
								armorMeshes[mesh] = true
								---c = mwscript.getItemCount({ reference = npcRef, item = obj })
								c = tes3.getItemCount({ reference = npcRef, item = obj })
								if c <= 0 then
									---mwscript.addItem({ reference = npcRef, item = obj, count = 1 })
									tes3.addItem({ reference = npcRef, item = obj, count = 1,
										playSound = false, updateGUI = false })
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
		mobile:unequip({clothingSlot = tes3_clothingSlot_amulet})
		local j = 1
		local m = 2
		if mobile.actorType
		and (mobile.actorType == tes3_actorType_player) then
			m = maxRingSlots
		end
		while j <= m do
			mobile:unequip({clothingSlot = tes3_clothingSlot_ring})
			j = j + 1
		end
	end

	tes3.messageBox({
		message = msg,
		buttons = { sYes, sNo },
		callback = function(e)
			if (e.button == 0) then
				debugOnce = true
				tes3ui.showNotifyMenu("%s: resetting amulet and rings, adding items...", modPrefix)
				unequipAmuletAndRings(mobilePlayer)
				giveDistinctItems(player)
			end
		end
	})
end

local function onDebugKeysPressed(e)
	if logLevel1 then
		if e.isAltDown and e.isShiftDown and (not debugOnce) then
			debugPressed()
		end
	end
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

local initDone = false
local function initOnce()
	if initDone then
		return
	end
	initDone = true
	event.register('equipped', equipped)
	event.register('unequipped', unequipped)
	event.register('mobileActivated', mobileActivated)
	-- Shift+Alt+D
	event.register('keyDown', onDebugKeysPressed, {filter=tes3.scanCode.d})
end

local function ab01vntyPT1()
	initVars()
	initOnce()
	initEquipment(player)
end

local function clearOffsets()
	amuletsOffset = {}
	ringsOffset = {}
	if tes3.player then
		initEquipment(tes3.player)
	end
end
	
local function loadOffsets()
	local data = player.data
	if not data then
		return
	end
	local ab01vntyAO = data.ab01vntyAO
	if ab01vntyAO then
		amuletsOffset = ab01vntyAO
		if logLevel2 then
			local s = ''
			local i = 0
			for k, v in pairs(amuletsOffset) do
				if v then
					i = i + 1
					s = s .. string.format('amuletsOffset["%s"] = {x = %s, y = %s, z = %s, s = %s}\n',
						k, v.x, v.y, v.z, v.s)
				end
			end
			if i > 0 then
				mwse.log(modPrefix..' loaded(): amuletsOffset\n'.. s)
			end
		end
	else
		amuletsOffset = {}
	end
	local ab01vntyRO = data.ab01vntyRO
	if ab01vntyRO then
		ringsOffset = ab01vntyRO
		if logLevel2 then
			local s = ''
			local i = 0
			for k, v in pairs(ringsOffset) do
				if v then
					i = i + 1
					s = s .. string.format('ringsOffset["%s"] = {y = %s, z = %s, s = %s}',
						k, v.y, v.z, v.s)
				end
			end
			if i > 0 then
				mwse.log(modPrefix..' loaded(): ringsOffset\n'.. s)
			end
		end
	else
		ringsOffset = {}
	end
end

local function loaded()
	initVars()
	initOnce()
	loadOffsets()
	initEquipment(player)
	debugOnce = false
	---cleanVisualCache()
	---cleanOldPlayerData()
end

local function onSave()
	local data = player.data
	if data then
		data.ab01vntyRO = ringsOffset
		data.ab01vntyAO = amuletsOffset
	end
end
--[[
event order test:
1 modConfigReady
2 initialized
3 mobileActivated
--]]
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

		updateFromConfig()

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

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	local yesOrNo = {[false] = sNo, [true] = sYes}

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	local optionList = {'Not visible', 'Bare Chest', 'Shirt', 'Cuirass', 'Robe'}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	controls:createDropdown{
		label = 'Amulet visibility level:',
		options = getOptions(),
		variable = createConfigVariable('viewAmuletLevel'),
		description = getDropDownDescription([[Default: %s.
Amulet visibility over selected item (and the lesser level ones). Default "4. Robe".
e.g. option "3. Cuirass" will make amulet visible on cuirass/shirt/bare chest but not on robe.
Note that positions are optimized for bare chest as shape and size of shirt, cuirass and robe may vary much more.]], 'viewAmuletLevel')
	}

	optionList = {'Not visible', 'Bare Hands', 'Gloves', 'Gauntlets'}
	controls:createDropdown{
		label = 'Rings visibility level:',
		options = getOptions(),
		variable = createConfigVariable('viewRingsLevel'),
		description = getDropDownDescription([[Default: %s.
Rings visibility over selected item (and the lesser level ones)
e.g. option "2. Gloves" will make rings visible on gloves/bare hands but not on gauntlets.
Note that positions are optimized for bare hands as shape and size of glove and gauntlet may vary much more.
]], 'viewRingsLevel')
	}

	optionList = {'Not visible', 'Equipped by Player', 'Equipped by NPCs', "In NPC's inventory"}
	controls:createDropdown{
		label = "Show amulets and rings:",
		options = getOptions(),
		variable = createConfigVariable('displayLevel'),
		description = getDropDownDescription([[Default: %s.
In NPC's inventory" option will display equipped/in inventory amulets and rings on any playable race NPC.
"0. Disabled" is mostly to temporarily disable the mod effects.
Disabling "2. Equipped by NPCs" or "3. In NPC's inventory" usually will refresh the
amulet and rings graphics on currently loaded NPCs on next cell load.
Only equipped amulet and rings will be visible on player (else it would become confusing to understand
what items you have currently equipped), while NPCs can show also unequipped amulet and rings.
This is because NPCs may not always equip items, and items equipped by NPCs are no more accessible
from NPCs inventory/barter menus so it's better to avoid messing with how default game/other mods equip them.
]], 'displayLevel')
	}

	local onUseRingExtraSlot = tes3.hasCodePatchFeature(tes3.codePatchFeature.onUseRingExtraSlot)
	local s = "%s: modConfigReady, Morrowind Code Patch option to enable 1 extra on-use ring slot "
	if onUseRingExtraSlot then
		maxRingSlots = 3
		mwse.log(s .. 'detected', modPrefix)
	else
		maxRingSlots = 2
		if maxVisibleRings > maxRingSlots then
			maxVisibleRings = maxRingSlots
			config.maxVisibleRings = maxVisibleRings
		end
		mwse.log(s .. 'NOT detected', modPrefix)
	end

	controls:createSlider{
		label = 'Max. number of visible rings',
		variable = createConfigVariable('maxVisibleRings'),
		description = getDescription([[Default: %s.
Max number of rings visible at the same time.
If you have the Morrowind Code Patch option to enable 1 extra ring slot
for enchanted-on-use rings, you should increase this value to 3.]], 'maxVisibleRings'),
		min = 1, max = maxRingSlots, step = 1, jump = 1
	}

	local storedInfo = '\nSaved if tweaked according to current player robe/cuirass/amulet meshes.'
	controls:createSlider{
		label = 'Amulet forward offset',
		variable = createConfigVariable('amuletForwardOffset'),
		description = getDescription([[Default: %s.
Amulet position forward offset (X 0.03).]]..storedInfo, 'amuletForwardOffset'),
		min = -250, max = 250, step = 1, jump = 5
	}

	controls:createSlider{
		label = 'Amulet side offset',
		variable = createConfigVariable('amuletSideOffset'),
		description = getDescription([[Default: %s.
Amulet position side offset (X 0.03).]]..storedInfo, 'amuletSideOffset'),
		min = -250, max = 250, step = 1, jump = 5
	}

	controls:createSlider{
		label = 'Amulet vertical offset',
		variable = createConfigVariable('amuletVerticalOffset'),
		description = getDescription([[Default: %s.
Amulet position vertical offset (X 0.03).]]..storedInfo, 'amuletVerticalOffset'),
		min = -250, max = 250, step = 1, jump = 5
	}

	controls:createSlider{
		label = 'Amulet scale (%)',
		variable = createConfigVariable('amuletScale'),
		description = getDescription([[Default: %s%%...storedInfo]], 'amuletScale'),
		min = 50, max = 200, step = 1, jump = 5
	}

	controls:createSlider{
		label = 'Ring forward offset',
		variable = createConfigVariable('ringForwardOffset'),
		description = getDescription([[Default: %s.
Ring position forward offset (X 0.0075).]], 'ringForwardOffset'),
		min = -250, max = 250, step = 1, jump = 5
	}

	controls:createSlider{
		label = 'Ring side offset',
		variable = createConfigVariable('ringSideOffset'),
		description = getDescription([[Default: %s.
Ring position side offset (X 0.0075).]], 'ringSideOffset'),
		min = -250, max = 250, step = 1, jump = 5
	}

	controls:createSlider{
		label = 'Ring scale (%)',
		variable = createConfigVariable('ringScale'),
		description = getDescription([[Default: %s%%.]], 'ringScale'),
		min = 50, max = 200, step = 1, jump = 5
	}

	controls:createButton{
		label = 'Update amulet and rings position according to sliders',
		description = [[
Setting Menu Transparency from in Game Options may allow to see the changes
to amulet and rings display on player while working in this MCM panel.
]],
		buttonText = "Update view",
		inGameOnly = true,
		callback = function()
			local ref = tes3.player
			if ref then
				initEquipment(ref)
			end
		end
	}

	controls:createButton({
		label = 'Clear saved amulets/rings positions',
		description = 'Clear/reset saved amulets/rings positions.',
		buttonText = 'Clear positions',
		callback = function()
			tes3.messageBox({
				message = 'Do you really want to clear all saved amulets/rings positions?',
				buttons = {'Yes', 'No'},
				callback = clearOffsets
			})		
		end
	})

	optionList = {'Minimum', 'Low', 'Medium', 'High', 'Max'}
	controls:createDropdown{
		label = 'Logging level:',
		options = getOptions(),
		variable = createConfigVariable('logLevel'),
		description = getDropDownDescription([[Default: %s.
If set higher than 0, pressing Shift+Alt+D will show
a debug testing option allowing you to reset amulet and rings visibility and get one
of each different looking amulets, rings, gloves, gauntlets, shirts, cuirasses, robes.
Warning: if your loading list is adding tons of these items, this will take some time and may appear to freeze your game, please wait!]], 'logLevel')
	}

	controls:createYesNoButton{
		label = 'In-game debug messages',
		variable = createConfigVariable('debugMessages'),
		description = getYesNoDescription([[Default: %s
Usually not needed.]], 'debugMessages')
	}

	local mcpDesc = "Morrowind Code Patch + Beta update option to enable 1 extra on-use ring slot highly suggested to enable one more shiny."

	local function createNexusLink(txt, decimalId, desc)
		if not desc then
			desc = mcpDesc
		end
		controls:createHyperlink({
			text = txt,
			url = string.format('https://www.nexusmods.com/morrowind/mods/%s', decimalId),
			confirm = false, -- why does not fucking work?
			description = desc
		})
	end

	createNexusLink('Morrowind Code Patch', 19510)
	createNexusLink('Morrowind Code Patch Beta Update', 26348,
		'run MWSE-Update.exe after installing MGE-XE to update MWSE-Lua')
	createNexusLink('MGE-XE/MWSE-Lua', 41102)
	createNexusLink('Better Bodies', 42395, [[
Amulets and rings positioning is tweaked/tested using Better Bodies (and optimized for Breton female race),
using vanilla/other body replacers may not work the same.
]])

	controls:createHyperlink({
		text = 'New Beast Bodies',
		url = 'https://web.archive.org/web/20161103113108/http://mw.modhistory.com/download-56-11364',
		confirm = false,
		description = [[
Amulets and rings positioning is tweaked/tested using New Beast Bodies,
using vanilla/other body replacers may not work the same.
]]
	})

	createNexusLink('Assetless No Glow', 47925, [[
If you install Assetless No Glow and delete any Textures/magicitem/caustXX.dds
you will still have no-glow armors but keep the pretty shiny glow on amulets and rings!
]])

	controls:createHyperlink({
		text = "abot's Morrowind mods on Nexus",
		url = 'https://www.nexusmods.com/users/38047?tab=user+files&BH=0',
		confirm = false
	})

	controls:createHyperlink({
		text = "abot's Morrowind site",
		url = 'https://abitoftaste.altervista.org/morrowind/',
		confirm = false
	})

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)


event.register('initialized',
function ()
	timer.register('ab01vntyPT1', ab01vntyPT1) -- using a persistent timer
	event.register('save', onSave)
	event.register('loaded', loaded)
	event.register('uiActivated', uiMenuRaceSexActivated, {filter = 'MenuRaceSex'})
end, {doOnce = true})
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
	local player = tes3.player
	if ref == tes3.player1stPerson then
		firstPersonNode = tes3.player1stPerson.sceneNode -- important to refresh this too!
		ref = player
	elseif ref.reference then -- in case ref is a mobile
		ref = ref.reference
	end
	---mwse.log('refreshNPC("%s")', ref.id)
	if ref == player then
		local equippedAmuletCount, equippedRingCount = initEquipment(ref)
		initNPCClothing(ref, equippedAmuletCount, equippedRingCount)
		return
	end
	refreshNPC(ref)
end
tes3.loadAnimation = newLoadAnimation