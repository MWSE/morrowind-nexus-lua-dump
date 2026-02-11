local BACKPACK_IDS = {
	sd_pouch = true,
	sd_backpack = true,
	
	sd_backpack_traveler = true,
	
	sd_backpack_adventurer = true,
	sd_backpack_adventurerblue = true,
	sd_backpack_adventurergreen = true,
	
	sd_backpack_velvetblue = true,
	sd_backpack_velvetbrown = true,
	sd_backpack_velvetgreen = true,
	sd_backpack_velvetpink = true,
	
	sd_backpack_satchelbrown = true,
	sd_backpack_satchelblue = true,
	sd_backpack_satchelblack = true,
	sd_backpack_satchelgreen = true,
}

-- Vertical position offsets for when backpacks spawn in the world
local BACKPACK_Z_OFFSETS = {
	sd_backpack = 0,
	sd_pouch = -30,
-- other ones use bounding box
}

local function getBaseId(equippedId)
	if equippedId:sub(-3) == "_eq" then
		return equippedId:sub(1, -4)
	end
	return nil
end

-- Register ItemUsage handler
I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, actor)
	if not types.Player.objectIsInstance(actor) then return end
	
	local itemId = item.recordId
	local baseId = getBaseId(itemId)
	
	-- If they used an equipped backpack, just convert it back
	if baseId and BACKPACK_IDS[baseId] then
		if item.count > 1 then
			item:split(1):remove()
		else
			item:remove()
		end
		world.createObject(baseId, 1):moveInto(types.Actor.inventory(actor))
		return
	end
	
	-- They used a base backpack - do the full swap
	if not BACKPACK_IDS[itemId] then return end
	
	local inv = types.Actor.inventory(actor)
	local newEquippedId = itemId .. "_eq"
	
	-- Find and convert any currently equipped backpack
	for _, invItem in ipairs(inv:getAll(types.Miscellaneous)) do
		local equippedBase = getBaseId(invItem.recordId)
		if equippedBase and BACKPACK_IDS[equippedBase] then
			-- Found equipped backpack - convert it back
			if invItem.count > 1 then
				invItem:split(1):remove()
			else
				invItem:remove()
			end
			world.createObject(equippedBase, 1):moveInto(inv)
			break
		end
	end
	
	-- Remove base backpack and create equipped version
	if item.count > 1 then
		item:split(1):remove()
	else
		item:remove()
	end
	world.createObject(newEquippedId, 1):moveInto(inv)
	
	-- Notify player of the equipped backpack
	actor:sendEvent("SunsDusk_backpackEquipped", { backpackId = newEquippedId })
end)

local function getBaseId(equippedId)
	if equippedId:sub(-3) == "_eq" then
		return equippedId:sub(1, -4)
	end
	return nil
end

local function onSwapBackpack(data)
	local item = data.item
	local actor = data.actor
	local currentEquipped = data.currentEquipped
	local inv = types.Actor.inventory(actor)
	local newEquippedId = data.itemId .. "_eq"
	
	-- Unequip old backpack if different
	if currentEquipped and currentEquipped ~= newEquippedId then
		local oldItem = inv:find(currentEquipped)
		if oldItem then
			local baseId = getBaseId(currentEquipped)
			if baseId then
				if oldItem.count > 1 then
					oldItem:split(1):remove()
				else
					oldItem:remove()
				end
				world.createObject(baseId, 1):moveInto(inv)
			end
		end
	end
	
	-- Remove base backpack and create equipped version
	if item.count > 1 then
		item:split(1):remove()
	else
		item:remove()
	end
	world.createObject(newEquippedId, 1):moveInto(inv)
	
	-- Tell player it's equipped
	actor:sendEvent("SunsDusk_backpackEquipped", { backpackId = newEquippedId })
end

local function convertEquippedBackpacksInCell(player)
	if not player then return end
	local cell = player.cell
	for _, obj in ipairs(cell:getAll(types.Miscellaneous)) do
		local baseId = getBaseId(obj.recordId)
		if baseId and BACKPACK_IDS[baseId] then
			local count, pos, rot = obj.count, obj.position, obj.rotation
			obj:remove()
			local offset = BACKPACK_Z_OFFSETS[baseId]
			if not offset then
				local bbox = obj:getBoundingBox()
				offset = -bbox.halfSize.z*0.9
				pos = bbox.center
			end
			local adjustedPos = util.vector3(pos.x, pos.y, pos.z + offset)
			world.createObject(baseId, count):teleport(cell, adjustedPos, rot)
		end
	end
	
	for _, container in ipairs(cell:getAll(types.Container)) do
		local inv = types.Container.content(container)
		for _, item in ipairs(inv:getAll(types.Miscellaneous)) do
			local baseId = getBaseId(item.recordId)
			if baseId and BACKPACK_IDS[baseId] then
				local count = item.count
				item:remove()
				world.createObject(baseId, count):moveInto(inv)
			end
		end
	end
	
	for _, actor in ipairs(cell:getAll(types.NPC)) do
		if not types.Player.objectIsInstance(actor) then
			local inv = types.Actor.inventory(actor)
			for _, item in ipairs(inv:getAll(types.Miscellaneous)) do
				local baseId = getBaseId(item.recordId)
				if baseId and BACKPACK_IDS[baseId] then
					local count = item.count
					item:remove()
					world.createObject(baseId, count):moveInto(inv)
				end
			end
		end
	end
	
	for _, actor in ipairs(cell:getAll(types.Creature)) do
		local inv = types.Actor.inventory(actor)
		for _, item in ipairs(inv:getAll(types.Miscellaneous)) do
			local baseId = getBaseId(item.recordId)
			if baseId and BACKPACK_IDS[baseId] then
				local count = item.count
				item:remove()
				world.createObject(baseId, count):moveInto(inv)
			end
		end
	end
end


G_eventHandlers.SunsDusk_swapBackpack = onSwapBackpack
G_eventHandlers.SunsDusk_convertInCell = convertEquippedBackpacksInCell