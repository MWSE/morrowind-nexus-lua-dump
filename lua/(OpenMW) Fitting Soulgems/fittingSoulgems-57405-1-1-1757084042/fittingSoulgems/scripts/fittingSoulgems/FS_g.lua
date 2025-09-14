local I = require('openmw.interfaces')
world = require('openmw.world')
local types = require('openmw.types')


local function flushSoulgem(data)
	local player = data.player
	local item = data.item
	local count = data.count
	
	local itemCount = item.count
	if not item:isValid() or itemCount == 0 then
		return 
	end
	
	print((types.Item.itemData(item).soul or "nil").." flushed out of "..item.recordId)

	local newObject = world.createObject(item.recordId,count)
	newObject:moveInto(player)
	item:remove(math.min(itemCount,count))
end

local function inventoryChanges(data)
	local player = data.player

	-- data.remove {item = itemTbl.ref, count = count} 
	for i, itemTbl in pairs(data.remove) do
		local count = math.min(itemTbl.item:isValid() and itemTbl.item.count or 0, itemTbl.count)
		if count>0 then
			print("REMOVED: "..itemTbl.item.recordId.." ["..tostring(types.Item.itemData(itemTbl.item).soul).."] x "..count)
			itemTbl.item:remove(count)
		end
	end
	
	-- data.add count 
	for recordId, count in pairs(data.add) do
		count = math.floor(count)
		if count > 0 then
			print("ADDED: "..recordId.." x "..count)
			local newObject = world.createObject(recordId, count)
			newObject:moveInto(player)
		end
	end
	
	-- data.addWithSouls {id = soulgemRecords[targetIndex].id, count = count, soul = itemTbl.soul}
	for i, itemTbl in pairs(data.addWithSouls) do
		count = math.floor(itemTbl.count)
		if count > 0 then
			print("ADDED: "..itemTbl.id.." ["..tostring(itemTbl.soul).."] x "..count)
			local newObject = world.createObject(itemTbl.id, count)
			types.Item.itemData(newObject).soul = itemTbl.soul
			newObject:moveInto(player)
		end
	end
end



return {
	--engineHandlers = { 
	--},
	eventHandlers = { 
		fittingSoulgems_flushSoulgem = flushSoulgem,
		fittingSoulgems_inventoryChanges = inventoryChanges,
	}
}