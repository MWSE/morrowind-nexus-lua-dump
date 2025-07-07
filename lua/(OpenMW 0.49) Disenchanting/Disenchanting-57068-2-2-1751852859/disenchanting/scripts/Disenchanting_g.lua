local I = require('openmw.interfaces')
world = require('openmw.world')
local disenchant = require("scripts.Disenchanting_disenchant")
local types = require('openmw.types')
local s = require("scripts.Disenchanting_settings")
local shiftStates = {}
local core = require('openmw.core')
I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, player)
	if types.Item.itemData(item).soul then
		if shiftStates[player.id] then
			player:sendEvent("disenchanting_consumeQuestion", item)
			return false
		end
		player:sendEvent("disenchanting_usedSoulgem", item)
	end
end)

local function disenchanting_disenchant(data)
	local player = data[1]
	local item = data[2]

	if not item:isValid() then
		return 
	elseif item.count == 0 then
		item = types.Player.inventory(player):find(item.recordId)
	end
	if not item:isValid() or item.count == 0 then
		return
	end
	local ret = disenchant(item, false, player)
	player:sendEvent("disenchanting_finishedDisenchanting", ret)
end

local function disenchanting_fixCapacity(data)
	local player = data[1]
	local item = data[2]
	local capacity = data[3]

	if not item:isValid() then
		return 
	elseif item.count == 0 then
		item = types.Player.inventory(player):find(item.recordId)
	end
	if not item:isValid() or item.count == 0 then
		return
	end
	
	local template = item.type.record(item)
	local weaponOrArmor = types.Weapon.objectIsInstance(item) or types.Armor.objectIsInstance(item)
	local condition = nil
	if weaponOrArmor then
		condition = types.Item.itemData(item).condition
	end
	
	--local tbl = {name = "Drained "..item.type.record(item).name,template = template, enchant = 1, value = ret.newValue, enchantCapacity = buggyInternalCapacity}
	local tbl = {template = template, enchantCapacity = capacity}
	local recordDraft = item.type.createRecordDraft(tbl)
	local newRecord = world.createRecord(recordDraft)
	local newObject = world.createObject(newRecord.id)
	if condition then
		types.Item.itemData(newObject).condition = condition
	end
	newObject:moveInto(player)
	--print(newObject.type.record(newObject).enchantCapacity/0.1*core.getGMST("FEnchantmentMult"))
	item:remove(1)
	player:sendEvent("disenchanting_refreshInventory")
end

local function disenchanting_multiplyPaper(data)
	local player = data[1]
	local item = data[2]
	local mult = data[3]

	if not item:isValid() then
		return 
	elseif item.count == 0 then
		item = types.Player.inventory(player):find(item.recordId)
	end
	if not item:isValid() or item.count == 0 then
		return
	end
	local amount = math.floor(mult-1)
	if math.random() < mult%1 then
		amount = amount + 1
	end
	if amount == 0 then
		return
	end
	local newObject = world.createObject(item.recordId, amount)
	newObject:moveInto(player)
	player:sendEvent("disenchanting_refreshInventory")
end

local function disenchanting_deleteSoulgem(data)
	local player = data[1]
	local item = data[2]
	if not item:isValid() or item.count == 0 then
		return
	end
	local soulValue = types.Item.itemData(item).soul and types.Creature.records[types.Item.itemData(item).soul] and types.Creature.records[types.Item.itemData(item).soul].soulValue
	if soulValue then
		if item.recordId == "misc_soulgem_azura" then
			soulValue = soulValue*0.7
			types.Item.itemData(item).soul = nil
		else
			item:remove(1)
		end
		player:sendEvent("disenchanting_finishedConsuming", soulValue)
	end
end

local function disenchanting_shiftToggled(data)
	local player = data[1]
	local state = data[2]
	shiftStates[player.id] = state
end

return {
	engineHandlers = { 
	},
	eventHandlers = { 
		disenchanting_disenchant = disenchanting_disenchant,
		disenchanting_shiftToggled = disenchanting_shiftToggled,
		disenchanting_deleteSoulgem = disenchanting_deleteSoulgem,
		disenchanting_fixCapacity = disenchanting_fixCapacity,
		disenchanting_multiplyPaper = disenchanting_multiplyPaper,
	}
}