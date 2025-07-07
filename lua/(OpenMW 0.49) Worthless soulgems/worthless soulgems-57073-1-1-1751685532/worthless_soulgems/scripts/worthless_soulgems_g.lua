local I = require('openmw.interfaces')
world = require('openmw.world')
local types = require('openmw.types')


local function replaceGem(data)
	local player = data[1]
	local item = data[2]
	local count = item.count
	if not item:isValid() or count == 0 then
		return 
	end
	local newRecordId = item.recordId.."_worthless"
	--print("replaceGem")
	local soul = types.Item.itemData(item).soul

	local newObject = world.createObject(newRecordId,count)
	--print(newObject.recordId)
	types.Item.itemData(newObject).soul = soul
	newObject:moveInto(player)
	
	item:remove(count)

end
-- Mapping table for soul gem replacement
local soulGemMapping = {
    ['misc_soulgem_common'] =   'misc_soulgem_common_worthless',
    ['misc_soulgem_grand'] =     'misc_soulgem_grand_worthless',
    ['misc_soulgem_greater'] = 'misc_soulgem_greater_worthless',
    ['misc_soulgem_lesser'] =   'misc_soulgem_lesser_worthless',
    ['misc_soulgem_petty'] =     'misc_soulgem_petty_worthless',
}

-- Function to replace soul gems
local function ChangeSoulGem(item)
    local Cell = item.cell
    local Position = item.position
    local Rotation = item.rotation
    local Soul = types.Miscellaneous.getSoul(item)
	local OwnerID = item.owner.recordId
	local OwnerFactionId = item.owner.factionId
	local OwnerFactionRank = item.owner.factionRank
    local newSoulGemId = soulGemMapping[item.recordId]

    if newSoulGemId then -- Check if there is a mapping for the item
        local NewSoulGem = world.createObject(newSoulGemId,item.count)
        if NewSoulGem then -- If the new soul gem was created successfully
            item:remove(item.count)
            NewSoulGem:teleport(Cell, Position, Rotation)
            types.Miscellaneous.setSoul(NewSoulGem, Soul)
            NewSoulGem.owner.recordId = OwnerID
            NewSoulGem.owner.factionId = OwnerFactionId
            NewSoulGem.owner.factionRank = OwnerFactionRank
        end
    end
end

local function changeMerchant(npc,player)
	for _,itemStack in pairs(types.NPC.inventory(npc):getAll()) do
		local itemId = itemStack.recordId
		local itemCount = itemStack.count
		local soul = types.Item.itemData(itemStack).soul
		if not types.Item.isRestocking(itemStack) and soulGemMapping[itemId] and soul then--and types.Item.itemData(itemStack).soul then
			--print("worthless soulgem "..itemId)
			itemStack:remove()
			local tempItem = world.createObject(soulGemMapping[itemId], itemCount)
			types.Item.itemData(tempItem).soul = soul
			tempItem:moveInto(types.NPC.inventory(npc))
		end
	end
	local npcRecordId = npc.recordId
	for _,cont in pairs(npc.cell:getAll(types.Container)) do
		if cont.owner.recordId == npcRecordId then
			if not types.Container.inventory(cont):isResolved() then
				types.Container.inventory(cont):resolve()
			end
			for _,itemStack in pairs(types.Container.inventory(cont):getAll()) do
				local itemId = itemStack.recordId
				local itemCount = itemStack.count
				local soul = types.Item.itemData(itemStack).soul
				if not types.Item.isRestocking(itemStack) and soulGemMapping[itemId] and soul then
					--print("worthless soulgem "..itemId)
					itemStack:remove()
					local tempItem = world.createObject(soulGemMapping[itemId], itemCount)
					types.Item.itemData(tempItem).soul = soul
					tempItem:moveInto(types.Container.inventory(cont))
				end
			end
		end
	end
	for _,itemStack in pairs(types.Player.inventory(player):getAll()) do
		local itemId = itemStack.recordId
		local itemCount = itemStack.count
		local soul = types.Item.itemData(itemStack).soul
		if soulGemMapping[itemId] and soul then
			--print("player worthless soulgem "..itemId)
			itemStack:remove()
			local tempItem = world.createObject(soulGemMapping[itemId], itemCount)
			types.Item.itemData(tempItem).soul = soul
			tempItem:moveInto(types.Player.inventory(player))
		end
	end
end

local function activateNPC(npc, player)
	if types.Actor.isDead(npc) then
		return
	end
	local npcRecordId = npc.recordId
	local npcRecord = types.NPC.record(npcRecordId)
	if not npcRecord or not npcRecord.servicesOffered.Barter then
		return
	end
	if disableMod then
		player:sendEvent("Restock_showMessage", "Version too old, Restock mod disabled")
		return
	end
		
	-- --if types.NPC.races.record(npcRecord.race).isBeast then
	-- --	local tempItem = world.createObject("ingred_moon_sugar_01",1)
	-- --	tempItem:moveInto(types.NPC.inventory(npc))
	-- --end
	-- 	--dbg("--------------")
	-- initMerchant(npc)
	-- 
	-- 	--dbg("---------------")
	-- checkCurrentStock(npc,player)
	-- 
	-- 	--dbg("---------------")
	-- vanillaRestock(npc)
	-- 
	-- 	--dbg("---------------")
	-- if globalSettings:get("INGREDIENT_RESTOCKING_MODE") ~= "Vanilla" then
	-- 	additionalIngredients(npc,player)
	-- end
	-- merchants[npcRecordId].currentStock = nil
	
	changeMerchant(npc,player)
end

I.Activation.addHandlerForType(types.NPC, activateNPC)



return {
	engineHandlers = { 
		onItemActive = function(item)
            if soulGemMapping[item.recordId] and types.Miscellaneous.getSoul(item) then
                ChangeSoulGem(item)
            end
        end,
	},
	eventHandlers = { 
		worthless_soulgems_replaceGem = replaceGem,
	}
}