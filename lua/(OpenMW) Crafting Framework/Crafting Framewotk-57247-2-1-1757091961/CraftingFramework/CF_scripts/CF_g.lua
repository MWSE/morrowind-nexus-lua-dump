local I = require('openmw.interfaces')
world = require('openmw.world')
types = require('openmw.types')
local core = require('openmw.core')
local vfs = require('openmw.vfs')

local protectedRecordIds = {
["t_de_ebony_pickaxe_01"] = true,
["bm nordic pick"] = true,
["miner's pick"] = true
}


local function getItem(data)
	local player = data[1]
	local recordType = data[2]
	local recordId = data[3]
	local customName = data[4]
	local count = data[5]
	local value = data[6]
	local qualityMult = data[7]
	
	if math.random() < count%1 then
		count = count + 1
	end
	
	local tempItem
	if protectedRecordIds[recordId] or recordType ~= "Armor" and recordType ~= "Weapon" and recordType ~= "Clothing" then
		tempItem = world.createObject(recordId, math.floor(count))
	elseif not qualityMult then
		if value then
			if not saveData.generatedRecords[recordId] then
				local tbl = {template = types[recordType].record(recordId), value = value}
				if customName then tbl.name = customName end
				local recordDraft = types[recordType].createRecordDraft(tbl)
				local newRecord = world.createRecord(recordDraft)
				saveData.generatedRecords[recordId] = newRecord.id
			end
			tempItem = world.createObject(saveData.generatedRecords[recordId], math.floor(count))
		else
			tempItem = world.createObject(recordId, math.floor(count))
		end
	else
		if not saveData.generatedRecords[recordId.."-"..qualityMult] then
			local originalRecord = types[recordType].record(recordId)
			local tbl = {template = originalRecord, value = value}
			if recordType == "Armor" then
				tbl.baseArmor = math.floor(originalRecord.baseArmor*qualityMult+0.5)
			elseif recordType == "Weapon" then
				local maxDamage = math.max(originalRecord.thrustMaxDamage, originalRecord.slashMaxDamage, originalRecord.chopMaxDamage)
				tbl.thrustMaxDamage = math.floor(math.max(originalRecord.thrustMaxDamage, maxDamage * 0.8)*qualityMult+0.5)
				tbl.slashMaxDamage = math.floor(math.max(originalRecord.slashMaxDamage, maxDamage * 0.8)*qualityMult+0.5)
				tbl.chopMaxDamage = math.floor(math.max(originalRecord.chopMaxDamage, maxDamage * 0.8)*qualityMult+0.5)
			elseif recordType == "Clothing" then
				tbl.enchantCapacity = math.floor(originalRecord.enchantCapacity*qualityMult+0.5)
			end
			if customName then tbl.name = customName end
			local recordDraft = types[recordType].createRecordDraft(tbl)
			local newRecord = world.createRecord(recordDraft)
			saveData.generatedRecords[recordId.."-"..qualityMult] = newRecord.id
		end
		tempItem = world.createObject(saveData.generatedRecords[recordId.."-"..qualityMult], math.floor(count))
	end
	tempItem:moveInto(player)
	player:sendEvent("CraftingFramework_notifyItem", {tempItem, math.floor(count),recordId})
end

local function removeItem(data)
	local player = data[1]
	local item = data[2]
	local count = data[3]
	if not item:isValid() or item.count == 0 then
		return
	end
	item:remove(count)
	player:sendEvent("CraftingFramework_removedItem", {item, math.floor(count)})
end


local function onSave()
    return saveData
end

local function onLoad(data)
	saveData = data or {}
	if not saveData.generatedRecords then
		saveData.generatedRecords = {}
	end
end


return {
	engineHandlers = {
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
	},
	eventHandlers = { 
		CraftingFramework_getItem = getItem,
		CraftingFramework_removeItem = removeItem,
	}
}