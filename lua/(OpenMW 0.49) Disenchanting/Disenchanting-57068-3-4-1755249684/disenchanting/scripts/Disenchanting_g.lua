local I = require('openmw.interfaces')
world = require('openmw.world')
local disenchant = require("scripts.Disenchanting_disenchant")
local types = require('openmw.types')
local s = require("scripts.Disenchanting_settings")
local shiftStates = {}
local core = require('openmw.core')
local vfs = require('openmw.vfs')
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

local effectNames = {["waterbreathing"] = "Water Breathing",
["swiftswim"] = "Swift Swim",
["waterwalking"] = "Water Walking",
["shield"] = "Shield",
["fireshield"] = "Fire Shield",
["lightningshield"] = "Lightning Shield",
["frostshield"] = "Frost Shield",
["burden"] = "Burden",
["feather"] = "Feather",
["jump"] = "Jump",
["levitate"] = "Levitate",
["slowfall"] = "SlowFall",
["lock"] = "Lock",
["open"] = "Open",
["firedamage"] = "Fire Damage",
["shockdamage"] = "Shock Damage",
["frostdamage"] = "Frost Damage",
["drainattribute"] = "Drain Attribute",
["drainhealth"] = "Drain Health",
["drainmagicka"] = "Drain Magicka",
["drainfatigue"] = "Drain Fatigue",
["drainskill"] = "Drain Skill",
["damageattribute"] = "Damage Attribute",
["damagehealth"] = "Damage Health",
["damagemagicka"] = "Damage Magicka",
["damagefatigue"] = "Damage Fatigue",
["damageskill"] = "Damage Skill",
["poison"] = "Poison",
["weaknesstofire"] = "Weakness to Fire",
["weaknesstofrost"] = "Weakness to Frost",
["weaknesstoshock"] = "Weakness to Shock",
["weaknesstomagicka"] = "Weakness to Magicka",
["weaknesstocommondisease"] = "Weakness to Common Disease",
["weaknesstoblightdisease"] = "Weakness to Blight Disease",
["weaknesstocorprusdisease"] = "Weakness to Corprus Disease",
["weaknesstopoison"] = "Weakness to Poison",
["weaknesstonormalweapons"] = "Weakness to Normal Weapons",
["disintegrateweapon"] = "Disintegrate Weapon",
["disintegratearmor"] = "Disintegrate Armor",
["invisibility"] = "Invisibility",
["chameleon"] = "Chameleon",
["light"] = "Light",
["sanctuary"] = "Sanctuary",
["nighteye"] = "Night Eye",
["charm"] = "Charm",
["paralyze"] = "Paralyze",
["silence"] = "Silence",
["blind"] = "Blind",
["sound"] = "Sound",
["calmhumanoid"] = "Calm Humanoid",
["calmcreature"] = "Calm Creature",
["frenzyhumanoid"] = "Frenzy Humanoid",
["frenzycreature"] = "Frenzy Creature",
["demoralizehumanoid"] = "Demoralize Humanoid",
["demoralizecreature"] = "Demoralize Creature",
["rallyhumanoid"] = "Rally Humanoid",
["rallycreature"] = "Rally Creature",
["dispel"] = "Dispel",
["soultrap"] = "Soultrap",
["telekinesis"] = "Telekinesis",
["mark"] = "Mark",
["recall"] = "Recall",
["divineintervention"] = "Divine Intervention",
["almsiviintervention"] = "Almsivi Intervention",
["detectanimal"] = "Detect Animal",
["detectenchantment"] = "Detect Enchantment",
["detectkey"] = "Detect Key",
["spellabsorption"] = "Spell Absorption",
["reflect"] = "Reflect",
["curecommondisease"] = "Cure Common Disease",
["cureblightdisease"] = "Cure Blight Disease",
["curecorprusdisease"] = "Cure Corprus Disease",
["curepoison"] = "Cure Poison",
["cureparalyzation"] = "Cure Paralyzation",
["restoreattribute"] = "Restore Attribute",
["restorehealth"] = "Restore Health",
["restoremagicka"] = "Restore Magicka",
["restorefatigue"] = "Restore Fatigue",
["restoreskill"] = "Restore Skill",
["fortifyattribute"] = "Fortify Attribute",
["fortifyhealth"] = "Fortify Health",
["fortifymagicka"] = "Fortify Magicka",
["fortifyfatigue"] = "Fortify Fatigue",
["fortifyskill"] = "Fortify Skill",
["fortifymaximummagicka"] = "Fortify Maximum Magicka",
["absorbattribute"] = "Absorb Attribute",
["absorbhealth"] = "Absorb Health",
["absorbmagicka"] = "Absorb Magicka",
["absorbfatigue"] = "Absorb Fatigue",
["absorbskill"] = "Absorb Skill",
["resistfire"] = "Resist Fire",
["resistfrost"] = "Resist Frost",
["resistshock"] = "Resist Shock",
["resistmagicka"] = "Resist Magicka",
["resistcommondisease"] = "Resist Common Disease",
["resistblightdisease"] = "Resist Blight Disease",
["resistcorprusdisease"] = "Resist Corprus Disease",
["resistpoison"] = "Resist Poison",
["resistnormalweapons"] = "Resist Normal Weapons",
["resistparalysis"] = "Resist Paralysis",
["removecurse"] = "Remove Curse",
["turnundead"] = "Turn Undead",
["summonscamp"] = "Summon Scamp",
["summonclannfear"] = "Summon Clannfear",
["summondaedroth"] = "Summon Daedroth",
["summondremora"] = "Summon Dremora",
["summonancestralghost"] = "Summon Ancestral Ghost",
["summonskeletalminion"] = "Summon Skeletal Minion",
["summonbonewalker"] = "Summon Bonewalker",
["summongreaterbonewalker"] = "Summon Greater Bonewalker",
["summonbonelord"] = "Summon Bonelord",
["summonwingedtwilight"] = "Summon Winged Twilight",
["summonhunger"] = "Summon Hunger",
["summongoldensaint"] = "Summon Golden Saint",
["summonflameatronach"] = "Summon Flame Atronach",
["summonfrostatronach"] = "Summon Frost Atronach",
["summonstormatronach"] = "Summon Storm Atronach",
["fortifyattack"] = "Fortify Attack",
["commandcreature"] = "Command Creature",
["commandhumanoid"] = "Command Humanoid",
["bounddagger"] = "Bound Dagger",
["boundlongsword"] = "Bound Longsword",
["boundmace"] = "Bound Mace",
["boundbattleaxe"] = "Bound Battle Axe",
["boundspear"] = "Bound Spear",
["boundlongbow"] = "Bound Longbow",
["extraspell"] = "EXTRA SPELL",
["boundcuirass"] = "Bound Cuirass",
["boundhelm"] = "Bound Helm",
["boundboots"] = "Bound Boots",
["boundshield"] = "Bound Shield",
["boundgloves"] = "Bound Gloves",
["corprus"] = "Corprus",
["vampirism"] = "Vampirism",
["summoncenturionsphere"] = "Summon Centurion Sphere",
["sundamage"] = "Sun Damage",
["stuntedmagicka"] = "Stunted Magicka"
}

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
		fixedName = fixedName.." of "..(effectNames[icon] or icon)
	end
	icon = "icons/lurlock/"..icon..".dds"
	if not vfs.fileExists(icon) then
		icon = "m/Tx_paper_plain_01.tga"
	end
	local tbl = {name = fixedName, template = template, icon = icon, weight = 0, value = 1, enchant = enchantment}
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

return {
	engineHandlers = { 
	},
	eventHandlers = { 
		disenchanting_disenchant = disenchanting_disenchant,
		disenchanting_shiftToggled = disenchanting_shiftToggled,
		disenchanting_deleteSoulgem = disenchanting_deleteSoulgem,
		disenchanting_fixCapacity = disenchanting_fixCapacity,
		disenchanting_multiplyPaper = disenchanting_multiplyPaper,
		disenchanting_disenchantWorldItem = disenchantWorldItem,
		disenchanting_consumeAll = disenchanting_consumeAll,
	}
}