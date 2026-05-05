local I = require('openmw.interfaces')
world = require('openmw.world')
local disenchant = require("scripts.Disenchanting_disenchant")
local types = require('openmw.types')
require("scripts.Disenchanting_settings")
local blacklist = require("scripts.Disenchanting_blacklist")
local shiftStates = {}
local core = require('openmw.core')
local vfs = require('openmw.vfs')

local saveData
local enchantSpellsBuilt = false

local function buildEnchantSpells()
	if enchantSpellsBuilt then return end
	enchantSpellsBuilt = true
	for _, effRecord in pairs(core.magic.effects.records) do
		local effId = effRecord.id
		if not blacklist[effId]
			and not core.magic.spells.records["enchantdummy_"..effId]
			and not saveData.spells[effId]
		then
			local effectEntry = {
				id = effId,
				range = core.magic.RANGE.Touch,
				area = 0,
				duration = 1,
				magnitudeMin = 1,
				magnitudeMax = 1,
			}
			if effRecord.hasSkill then
				effectEntry.affectedSkill = "block"
			end
			if effRecord.hasAttribute then
				effectEntry.affectedAttribute = "agility"
			end
			local draft = core.magic.spells.createRecordDraft({
				name = "Disenchanted "..effId,
				type = core.magic.SPELL_TYPE.Spell,
				cost = 1,
				isAutocalc = true,
				effects = {effectEntry},
			})
			local ok, newSpell = pcall(world.createRecord, draft)
			if ok and newSpell then
				saveData.spells[effId] = newSpell.id
			else
				print("disenchanting: failed to build dummy spell for "..effId..": "..tostring(newSpell))
			end
		end
	end
end
creatures = {}
for a,b in pairs(types.Creature.records) do
	if b.name ~= "" and not b.name:lower():find("deprecated") then
		table.insert(creatures, {b.id, b.soulValue})
	end
end
table.sort(creatures, function(a,b) return a[2]<b[2] end)
--for a,b in pairs(creatures) do
--	print(b[1],b[2])
--end

bestInSlot = {}
for _, cat in pairs{
	types.Armor,
	types.Weapon,
	types.Clothing
} do
	local records = cat.records
	local catString = tostring(cat)
	for _,record in pairs(records) do
		if record.id:sub(1, #"Generated") ~= "Generated" and not record.id:lower():find("_uni") and not record.enchant then --wabbajack fixed t_dae_uni_wabbajack
			bestInSlot[catString.."-"..record.type] = math.max((bestInSlot[catString.."-"..record.type] or 0), record.enchantCapacity)
		end
	end
end


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

local function disenchantWorldItem(data)
	local player = data[1]
	local item = data[2]
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
	local name = template.name
	name = name:gsub("^Drained ", "")
	name = name:gsub(" %b[]$", "")
	
	--local tbl = {name = "Drained "..item.type.record(item).name,template = template, enchant = 1, value = ret.newValue, enchantCapacity = buggyInternalCapacity}
	local tbl = {template = template, enchantCapacity = capacity, name = name}
	
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
	local amount = math.floor(mult)
	if math.random() < mult%1 then
		amount = amount + 1
	end
	if not item:isValid() then
		return 
	elseif item.count == 0 then
		item = types.Player.inventory(player):find(item.recordId)
	end
	if not item:isValid() or item.count == 0 then
		return
	end

	
	--local tbl = {name = "Drained "..item.type.record(item).name,template = template, enchant = 1, value = ret.newValue, enchantCapacity = buggyApiCapacity}
	local record = item.type.record(item)
	local enchantment = item and (record.enchant or record.enchant ~= "" and record.enchant )
	local enchantmentRecord = core.magic.enchantments.records[enchantment]
	if not enchantmentRecord then return nil end
	
	local icon = nil
	for _, eff in pairs(enchantmentRecord.effects) do
		if eff.id then
			icon = eff.id			
		end
	end
	if not icon then return end
	local fixedName = item.type.record(item).name
	if fixedName:lower() == "paper" or fixedName:lower() == "papier" then
		local effectRecord = core.magic.effects.records[icon]
		fixedName = fixedName.." of "..( effectRecord and effectRecord.name or icon)
	end
	icon = "icons/lurlock/"..icon..".dds"
	if not vfs.fileExists(icon) then
		icon = "m/Tx_paper_plain_01.tga"
	end
	local tbl = {name = fixedName, template = record, icon = icon, weight = 0, value = 1, enchant = enchantment}
	local recordDraft = item.type.createRecordDraft(tbl)
	local newRecord = world.createRecord(recordDraft)
	local newObject = world.createObject(newRecord.id, amount)

	newObject:moveInto(player)
	item:remove(1)
	
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

-- consume the entire stack of a soul gem in one go
local function disenchanting_deleteSoulgemStack(data)
	local player = data[1]
	local item = data[2]
	if not item:isValid() or item.count == 0 then
		return
	end
	local soulId = types.Item.itemData(item).soul
	local creature = soulId and types.Creature.records[soulId]
	if not creature then return end
	local soulValue = creature.soulValue
	local count = item.count
	if item.recordId == "misc_soulgem_azura" then
		-- azura's gem is reusable: only the soul leaves, the gem stays
		soulValue = soulValue * 0.7
		types.Item.itemData(item).soul = nil
		count = 1
	else
		item:remove(count)
	end
	player:sendEvent("disenchanting_finishedConsumingStack", {
		soulValue = soulValue,
		count = count,
	})
end

local function disenchanting_consumeAll(data)
	local player = data
	for i, item in pairs(types.Player.inventory(player):getAll(types.Miscellaneous)) do
		if not item:isValid() or item.count == 0 then
			return
		end
		for i=1, item.count do
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
	end
end

local function disenchanting_shiftToggled(data)
	local player = data[1]
	local state = data[2]
	shiftStates[player.id] = state
end

local function disenchanting_requestSpellMap(player)
	buildEnchantSpells()
	player:sendEvent("disenchanting_setSpellMap", saveData.spells)
end

local function onSave()
	return saveData
end

local function onLoad(data)
	saveData = data or {}
	saveData.spells = saveData.spells or {}
end

return {
	engineHandlers = {
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
	},
	eventHandlers = {
		disenchanting_disenchant = disenchanting_disenchant,
		disenchanting_shiftToggled = disenchanting_shiftToggled,
		disenchanting_deleteSoulgem = disenchanting_deleteSoulgem,
		disenchanting_deleteSoulgemStack = disenchanting_deleteSoulgemStack,
		disenchanting_fixCapacity = disenchanting_fixCapacity,
		disenchanting_multiplyPaper = disenchanting_multiplyPaper,
		disenchanting_disenchantWorldItem = disenchantWorldItem,
		disenchanting_consumeAll = disenchanting_consumeAll,
		disenchanting_requestSpellMap = disenchanting_requestSpellMap,
	}
}