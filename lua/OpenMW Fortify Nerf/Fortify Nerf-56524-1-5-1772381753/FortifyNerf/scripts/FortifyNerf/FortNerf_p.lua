local I = require("openmw.interfaces")
local core = require("openmw.core")
local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local async = require('openmw.async')
local MOD_NAME = "FortifyNerf"
local playerSection = storage.playerSection("SettingsPlayer" .. MOD_NAME)
local Player = require('openmw.types').Player
local Actor = require('openmw.types').Actor
local skills = types.NPC.stats.skills
local attributes = types.Actor.stats.attributes
local activeSpells = Actor.activeSpells(self)
local activeEffects = Actor.activeEffects(self)

local attrCache = {}
for name, _ in pairs(attributes) do
	attrCache[name] = attributes[name](self)
end

local skillCache = {}
for name, _ in pairs(skills) do
	skillCache[name] = skills[name](self)
end

whitelist = {
	-- Combat Skills
	--	["armorer"]	 = 1,
		["athletics"]   = 0.9,
		["axe"]		 = 0.9,
		["block"]	   = 1,
		["bluntweapon"] = 0.9,
		["heavyarmor"]  = 1.2,
		["longblade"]   = 0.9,
		["mediumarmor"] = 1.1,
		["spear"]	   = 0.9,
	
	-- Magic Skills
	--	["alchemy"]	 = 1,
	--	["alteration"]  = 1.4,
	--	["conjuration"] = 1.5,
	--	["destruction"] = 0.9,
	--	["enchant"]	 = 1.1,
	--	["illusion"]	= 1.5,
	--	["mysticism"]   = 1.5,
	--	["restoration"] = 1,
		["unarmored"]   = 1.3,
	
	-- Stealth Skills
		["acrobatics"]  = 0.8,
		["handtohand"]  = 0.9,
		["lightarmor"]  = 1.1,
		["marksman"]	= 0.9,
	--	["mercantile"]  = 1,
	--	["security"]	= 1.1,
		["shortblade"]  = 0.9,
	--	["sneak"]	   = 1.6,
	--	["speechcraft"] = 1.1,
	
	-- Attributes
		["strength"]	   = 1.6,
		["agility"]	   = 1.6,
		["speed"]	   = 1.6,
		["endurance"]	   = 1.6,
	--	["intelligence"]	   = 1.6,
	--	["willpower"]	   = 1.6,
	--	["personality"]	   = 1.6,
		["luck"]	   = 1.6,
}

nerfUIs = {
	["Dialogue"] = true,
	["Container"] =true,
	["SpellBuying"] = true,
	["SpellCreation"] = true,
	["Barter"] = true,
	["Alchemy"] = true,
	["Recharge"] = true,
	["Enchanting"] = true,
	["Training"] = true,
	["MerchantRepair"] = true,
	["Repair"] = true,
	["Travel"] = true,
}

local settingsTemplate = {
	key = "SettingsPlayer" .. MOD_NAME,
	l10n = "none",
	name = "",
	page = MOD_NAME,
	description = "",
	permanentStorage = true,
	settings = {
		{
			key = "maxDuration",
			name = "Fortify Spell Duration For Max Effect",
			description = "The duration needed by your fortify spells to reach their max magnitude in tradeskill menus.\nDefault: fEnchantmentConstantDurationMult/2 GMST (100/2 in vanilla)",
			default = core.getGMST("fEnchantmentConstantDurationMult") / 2,
			renderer = 'number',
			argument = {
				min = 1,
				max = 10000,
			},
		},
		{
			key = "buffCap",
			name = "Max Temporary Fortify Magnitude",
			description = "Caps the cumulated magnitude of each fortify type at this value.\nOnly counts temporary fortify effects\nAlchemy and magic have their seperate limits",
			default = 100,
			renderer = 'number',
			argument = {
				min = 1,
				max = 10000,
			},
		},
		{
			key = "onlyBestBuff",
			name = "onlyBestBuff",
			description = "Use only the best buff for each attribute/skill (one from alchemy and one from magic)",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "alwaysActive",
			name = "alwaysActive",
			description = "runs every frame and not just when crafting",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "useDurationLeft",
			name = "useDurationLeft",
			description = "instead of the max duration of the buff",
			default = false,
			renderer = "checkbox",
		},
	}
}

I.Settings.registerPage {
	key = MOD_NAME,
	l10n = "none",
	name = "FortifyNerf",
	description = ""
}

I.Settings.registerGroup(settingsTemplate)

-- Cache settings into S_ prefixed globals
local function readAllSettings()
	for _, entry in pairs(settingsTemplate.settings) do
		local value = playerSection:get(entry.key)
		if value == nil then
			value = entry.default
		end
		_G["S_"..entry.key] = value
	end
end

readAllSettings()
playerSection:subscribe(async:callback(function(_, setting)
	local value = playerSection:get(setting)
	if value == nil then
		for _, entry in pairs(settingsTemplate.settings) do
			if entry.key == setting then
				value = entry.default
				break
			end
		end
	end
	_G["S_"..setting] = value
end))

-- Cache: spellId -> false (no fortify), 1 (fortify, alchemy), 2 (fortify, spell record)
local spellInfoCache = {}

local function getSpellInfo(spell)
	local id = spell.id
	local cached = spellInfoCache[id]
	if cached ~= nil then return cached end
	local result = false
	local record = core.magic.spells.records[id]
	if record then
		for _, effect in pairs(record.effects) do
			if effect.id == "fortifyattribute" or effect.id == "fortifyskill" then
				result = 2
				break
			end
		end
	else
		local potion = types.Potion.records[id]
		if potion then
			for _, effect in pairs(potion.effects) do
				if effect.id == "fortifyattribute" or effect.id == "fortifyskill" then
					result = 1
					break
				end
			end
		else
			-- Enchanted item (equipped)
			local source = nil
			if spell.item then
				local enchantId = spell.item.type.record(spell.item).enchant or ""
				source = core.magic.enchantments.records[enchantId]
			end
			-- Scroll (item may already be consumed)
			if not source then
				local bookRecord = types.Book.records[id]
				if bookRecord then
					local enchantId = bookRecord.enchant or ""
					source = core.magic.enchantments.records[enchantId]
				end
			end
			if source then
				for _, effect in pairs(source.effects) do
					if effect.id == "fortifyattribute" or effect.id == "fortifyskill" then
						result = 2
						break
					end
				end
			end
		end
	end
	spellInfoCache[id] = result
	return result
end

local function reportToAAM()
	if I.AAM then
		local report = {}
		for attr, amount in pairs(nerfedAttributes) do
			report[attr] = -amount
		end
		for skill, amount in pairs(nerfedSkills) do
			report[skill] = -amount
		end
		I.AAM.reportExternalModifiers("FortifyNerf", report)
	end
end

local function applyNerf()
	local skillBuffs = {}
	local alchemySkillBuffs = {}
	local attributeBuffs = {}
	local alchemyAttributeBuffs = {}
	for _, spell in pairs(activeSpells) do
		local info = getSpellInfo(spell)
		if info then
			-- info==2: spell record with fortify, info==1: alchemy with fortify
			local thisSpellSkills = {}
			local thisSpellSkillsTotal = {}
			local thisSpellAttributes = {}
			local thisSpellAttributesTotal = {}
			local hasFortify = false
			for _, effect in pairs(spell.effects) do
				if effect.id == "fortifyattribute" and effect.duration and not whitelist[effect.affectedAttribute] then
					hasFortify = true
					local duration = S_useDurationLeft and effect.durationLeft or effect.duration
					--print(spell, duration)
					local adjustedBuff = math.floor(effect.magnitudeThisFrame * (math.max(0, math.min(1, duration / S_maxDuration))))
					thisSpellAttributes[effect.affectedAttribute] = (thisSpellAttributes[effect.affectedAttribute] or 0) + adjustedBuff
					thisSpellAttributesTotal[effect.affectedAttribute] = (thisSpellAttributesTotal[effect.affectedAttribute] or 0) + effect.magnitudeThisFrame
				elseif effect.id == "fortifyskill" and effect.duration and not whitelist[effect.affectedSkill] then
					hasFortify = true
					local duration = S_useDurationLeft and effect.durationLeft or effect.duration
					local adjustedBuff = math.floor(effect.magnitudeThisFrame * (math.max(0, math.min(1, duration / S_maxDuration))))
					thisSpellSkills[effect.affectedSkill] = (thisSpellSkills[effect.affectedSkill] or 0) + adjustedBuff
					thisSpellSkillsTotal[effect.affectedSkill] = (thisSpellSkillsTotal[effect.affectedSkill] or 0) + effect.magnitudeThisFrame
				end
			end
			if hasFortify then
				local isSpellRecord = info == 2
				for attribute, magnitude in pairs(thisSpellAttributes) do
					local target = isSpellRecord and attributeBuffs or alchemyAttributeBuffs
					if not target[attribute] then
						target[attribute] = {}
					end
					table.insert(target[attribute], {adjusted = magnitude, base = thisSpellAttributesTotal[attribute]})
				end
				for skill, magnitude in pairs(thisSpellSkills) do
					local target = isSpellRecord and skillBuffs or alchemySkillBuffs
					if not target[skill] then
						target[skill] = {}
					end
					table.insert(target[skill], {adjusted = magnitude, base = thisSpellSkillsTotal[skill]})
				end
			end
		end
	end
	local function subcompute(attrBuffs, skillBuffs)
		local totalSkillBuffs = {}
		local totalSkillBuffsBase = {}
		local totalAttributeBuffs = {}
		local totalAttributeBuffsBase = {}
		local bestAttributeBuff = {}
		local bestSkillBuff = {}
		for attribute, spells in pairs(attrBuffs) do
			for _, entry in pairs(spells) do
				totalAttributeBuffs[attribute] = (totalAttributeBuffs[attribute] or 0) + entry.adjusted
				totalAttributeBuffsBase[attribute] = (totalAttributeBuffsBase[attribute] or 0) + entry.base
				bestAttributeBuff[attribute] = math.max(bestAttributeBuff[attribute] or 0, entry.adjusted)
			end
		end
		for skill, spells in pairs(skillBuffs) do
			for _, entry in pairs(spells) do
				totalSkillBuffs[skill] = (totalSkillBuffs[skill] or 0) + entry.adjusted
				totalSkillBuffsBase[skill] = (totalSkillBuffsBase[skill] or 0) + entry.base
				bestSkillBuff[skill] = math.max(bestSkillBuff[skill] or 0, entry.adjusted)
			end
		end
		for attribute in pairs(totalAttributeBuffs) do
			local nerfAmount
			if S_onlyBestBuff then
				nerfAmount = totalAttributeBuffsBase[attribute] - math.min(S_buffCap, bestAttributeBuff[attribute])
			else
				nerfAmount = totalAttributeBuffsBase[attribute] - math.min(S_buffCap, totalAttributeBuffs[attribute])
			end
			nerfedAttributes[attribute] = (nerfedAttributes[attribute] or 0) + nerfAmount
			attrCache[attribute].modifier = attrCache[attribute].modifier - nerfAmount
			--print(attribute.." -"..nerfAmount)
		end
		for skill in pairs(totalSkillBuffs) do
			local nerfAmount
			if S_onlyBestBuff then
				nerfAmount = totalSkillBuffsBase[skill] - math.min(S_buffCap, bestSkillBuff[skill])
			else
				nerfAmount = totalSkillBuffsBase[skill] - math.min(S_buffCap, totalSkillBuffs[skill])
			end
			nerfedSkills[skill] = (nerfedSkills[skill] or 0) + nerfAmount
			skillCache[skill].modifier = skillCache[skill].modifier - nerfAmount
		end
	end
	subcompute(attributeBuffs, skillBuffs)
	subcompute(alchemyAttributeBuffs, alchemySkillBuffs)
	nerfActive = true
	reportToAAM()
end

local function undoNerf()
	if nerfActive then
		for attribute, amount in pairs(nerfedAttributes) do
			attrCache[attribute].modifier = attrCache[attribute].modifier + amount
			--print(attribute.." +"..amount)
		end
		nerfedAttributes = {}
		for skill, amount in pairs(nerfedSkills) do
			skillCache[skill].modifier = skillCache[skill].modifier + amount
		end
		nerfedSkills = {}
		nerfActive = false
		reportToAAM()
	end
end

function uiModeChanged(data)
	if S_alwaysActive or data.newMode and nerfUIs[data.newMode] then
		undoNerf()
		applyNerf()
	else
		undoNerf()
	end
end

local nextNerfCheck = 0

local function onFrame(dt)
	if not S_alwaysActive then return end
	if dt == 0 then return end
	local now = core.getSimulationTime()
	if now < nextNerfCheck then return end
	nextNerfCheck = now + 0.2
	-- Early-out: no fortify attribute or skill effects active at all
	local fortAttr = activeEffects:getEffect("fortifyattribute").magnitude
	local fortSkill = activeEffects:getEffect("fortifyskill").magnitude
	if (not fortAttr or fortAttr == 0) and (not fortSkill or fortSkill == 0) then
		undoNerf()
		return
	end
	undoNerf()
	applyNerf()
end


local function onInit()
	nerfedSkills = {}
	nerfedAttributes = {}
	nerfActive = false
	loadCounter = 1
	return {nerfedSkills = nerfedSkills, nerfedAttributes = nerfedAttributes, nerfActive = nerfActive, loadCounter = 1}
end

local function onLoad(data)
	if not data or not data.nerfedSkills then
		nerfedSkills = {}
		nerfedAttributes = {}
		nerfActive = false
		loadCounter = 1
	else
		nerfedSkills = data.nerfedSkills
		nerfedAttributes = data.nerfedAttributes
		nerfActive = data.nerfActive
		loadCounter = data.loadCounter + 1
	end
end

local function onSave()
	return {nerfedSkills = nerfedSkills, nerfedAttributes = nerfedAttributes, nerfActive = nerfActive, loadCounter = loadCounter}
end



return {
	eventHandlers = {
		UiModeChanged = uiModeChanged,
	},
	engineHandlers = {
		onFrame = onFrame,
		onLoad = onLoad,
		onSave = onSave,
		onInit = onInit,
	}
}