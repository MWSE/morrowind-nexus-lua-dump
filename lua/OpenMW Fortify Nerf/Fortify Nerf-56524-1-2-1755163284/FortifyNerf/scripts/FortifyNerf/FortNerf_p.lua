local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local core = require("openmw.core")
local types = require('openmw.types')
local self = require('openmw.self')
local ambient = require('openmw.ambient')
local resources = types.Actor.stats.dynamic
local MODE = I.UI.MODE
local MOD_NAME = "FortifyNerf"
local storage = require('openmw.storage')
local playerSection = storage.playerSection("SettingsPlayer" .. MOD_NAME)
local async = require('openmw.async')
local I = require("openmw.interfaces")
local UI = require('openmw.interfaces').UI
local skills = require('openmw.types').NPC.stats.skills
local attributes = require('openmw.types').Actor.stats.attributes
--stored on save
--local nerfedSkills = {}
--local nerfedAttributes = {}
--local nerfActive = false

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


I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = "FortifyNerf",
	description = ""
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. MOD_NAME,
	l10n = MOD_NAME,
	name = "",
	page = MOD_NAME,
	description = "",
	permanentStorage = true,
	settings = {
		{
			key = "maxDuration",
			name = "Fortify Spell Duration For Max Effect",
			description = "The duration needed by your fortify spells to reach their max magnitude in tradeskill menus.\nDefault: fEnchantmentConstantDurationMult/2 GMST (100/2 in vanilla)",
			default =core.getGMST("fEnchantmentConstantDurationMult")/2, 
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
			default =100, 
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
local function applyNerf()
	local skillBuffs = {}
	local alchemySkillBuffs = {}
	local attributeBuffs = {}
	local alchemyAttributeBuffs = {}
	for a,b in pairs(types.Actor.activeSpells(self)) do
		local spell = core.magic.spells.records[b.id]
		local thisSpellSkills = {}
		local thisSpellSkillsTotal = {}
		local thisSpellAttributes = {}
		local thisSpellAttributesTotal = {}
		for c,d in pairs(b.effects) do
			if d.id == "fortifyattribute" and d.duration and not whitelist[d.affectedAttribute] then
				local duration = playerSection:get("useDurationLeft") and d.durationLeft or d.duration
				local adjustedBuff = math.floor(d.magnitudeThisFrame*(math.max(0,math.min(1, duration / playerSection:get("maxDuration")))))
				thisSpellAttributes[d.affectedAttribute] = (thisSpellAttributes[d.affectedAttribute] or 0) + adjustedBuff
				thisSpellAttributesTotal[d.affectedAttribute] = (thisSpellAttributesTotal[d.affectedAttribute] or 0) + d.magnitudeThisFrame
			elseif d.id == "fortifyskill" and d.duration and not whitelist[d.affectedSkill] then
				local duration = playerSection:get("useDurationLeft") and d.durationLeft or d.duration
				local adjustedBuff = math.floor(d.magnitudeThisFrame*(math.max(0,math.min(1, duration / playerSection:get("maxDuration")))))
				thisSpellSkills[d.affectedSkill] = (thisSpellSkills[d.affectedSkill] or 0) + adjustedBuff
				thisSpellSkillsTotal[d.affectedSkill] = (thisSpellSkillsTotal[d.affectedSkill] or 0) + d.magnitudeThisFrame
			end
		end
		for attribute,magnitude in pairs(thisSpellAttributes) do
			if spell then
				if not attributeBuffs[attribute] then
					attributeBuffs[attribute]={}
				end
				table.insert(attributeBuffs[attribute],{adjusted = thisSpellAttributes[attribute], base = thisSpellAttributesTotal[attribute]})
			else
				if not alchemyAttributeBuffs[attribute] then
					alchemyAttributeBuffs[attribute]={}
				end
				table.insert(alchemyAttributeBuffs[attribute],{adjusted = thisSpellAttributes[attribute], base = thisSpellAttributesTotal[attribute]})
			end
		end
		for skill,magnitude in pairs(thisSpellSkills) do
			if spell then
				if not skillBuffs[skill] then
					skillBuffs[skill]={}
				end
				table.insert(skillBuffs[skill],{adjusted = thisSpellSkills[skill], base = thisSpellSkillsTotal[skill]})
			else
				if not alchemySkillBuffs[skill] then
					alchemySkillBuffs[skill]={}
				end
				table.insert(alchemySkillBuffs[skill],{adjusted = thisSpellSkills[skill], base = thisSpellSkillsTotal[skill]})
			end
		end
	end
	local function subcompute(a, s)
		local totalSkillBuffs = {}
		local totalSkillBuffsBase = {}
		local totalAttributeBuffs = {}
		local totalAttributeBuffsBase = {}
		local bestAttributeBuff = {}
		local bestSkillBuff = {}
		for attribute,spells in pairs(a) do
			for i, t in pairs(spells) do
				totalAttributeBuffs[attribute] = (totalAttributeBuffs[attribute] or 0) + t.adjusted
				totalAttributeBuffsBase[attribute] = (totalAttributeBuffsBase[attribute] or 0) + t.base
				bestAttributeBuff[attribute] = math.max(bestAttributeBuff[attribute] or 0, t.adjusted)
			end
		end
		for skill,spells in pairs(s) do
			for i, t in pairs(spells) do
				totalSkillBuffs[skill] = (totalSkillBuffs[skill] or 0) + t.adjusted
				totalSkillBuffsBase[skill] = (totalSkillBuffsBase[skill] or 0) + t.base
				bestSkillBuff[skill] = math.max(bestSkillBuff[skill] or 0, t.adjusted)
			end
		end
		for attribute, magnitude in pairs(totalAttributeBuffs) do
			if playerSection:get("onlyBestBuff") then
				local nerfAmount = totalAttributeBuffsBase[attribute] - math.min(playerSection:get("buffCap"),bestAttributeBuff[attribute])
				--print("nerfAmount",nerfAmount)
				--print("modifier before",attributes[attribute](self).modifier)
				nerfedAttributes[attribute] = (nerfedAttributes[attribute] or 0) + nerfAmount
				attributes[attribute](self).modifier = attributes[attribute](self).modifier - nerfAmount
				--print(nerfedAttributes[attribute] ,attributes[attribute](self).modifier, nerfAmount,bestAttributeBuff[attribute])
			else
				local nerfAmount = totalAttributeBuffsBase[attribute] - math.min(playerSection:get("buffCap"),totalAttributeBuffs[attribute])
				nerfedAttributes[attribute] = (nerfedAttributes[attribute] or 0) + nerfAmount
				attributes[attribute](self).modifier = attributes[attribute](self).modifier - nerfAmount
			end
		end
		for skill, magnitude in pairs(totalSkillBuffs) do
			if playerSection:get("onlyBestBuff") then
				local nerfAmount = totalSkillBuffsBase[skill] - math.min(playerSection:get("buffCap"),bestSkillBuff[skill])
				nerfedSkills[skill] = (nerfedSkills[skill] or 0) + nerfAmount
				skills[skill](self).modifier = skills[skill](self).modifier - nerfAmount
			else
				local nerfAmount = totalSkillBuffsBase[skill] - math.min(playerSection:get("buffCap"),totalSkillBuffs[skill])
				nerfedSkills[skill] = (nerfedSkills[skill] or 0) + nerfAmount
				skills[skill](self).modifier = skills[skill](self).modifier - nerfAmount
			end
		end
	end
	subcompute(attributeBuffs,skillBuffs)
	subcompute(alchemyAttributeBuffs,alchemySkillBuffs)
	nerfActive = true
end

local function undoNerf()
	if nerfActive then
		for a,b in pairs(nerfedAttributes) do
			attributes[a](self).modifier = attributes[a](self).modifier + b
		end
		nerfedAttributes = {}
		for a,b in pairs(nerfedSkills) do
			skills[a](self).modifier = skills[a](self).modifier + b
		end
		nerfedSkills = {}
		nerfActive = false
	end
end

function uiModeChanged(data)
	if playerSection:get("alwaysActive") or data.newMode and nerfUIs[data.newMode] then
		undoNerf()
		applyNerf()
	else
		undoNerf()
	end
	--if data.newMode and nerfUIs[data.newMode] then
	--	if not nerfActive then
	--		applyNerf()
	--	end
	--elseif nerfActive then
	--	undoNerf()
	--end
	--print(attributes["willpower"](self).modifier)
end
local function userDataLength (userData)
	local i = 0
	for _ in pairs(userData) do
		i=i+1
	end
	return i
end
local activeSpells = userDataLength(types.Actor.activeSpells(self))

local function onFrame(dt)
	if dt == 0 and activeSpells == userDataLength(types.Actor.activeSpells(self)) then
		return
	end
	activeSpells = userDataLength(types.Actor.activeSpells(self))
	if playerSection:get("alwaysActive") then
		undoNerf()
		applyNerf()
	end
end


local function onInit()
	nerfedSkills = {}
	nerfedAttributes = {}
	nerfActive = false
	loadCounter = 1
	--print("FortNerf")
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
		loadCounter = data.loadCounter+1
	end
	--print("FortNerf "..loadCounter)
end

local function onSave()
	return {nerfedSkills = nerfedSkills, nerfedAttributes = nerfedAttributes, nerfActive = nerfActive, loadCounter = loadCounter}
end



return {
	eventHandlers = {
		UiModeChanged = uiModeChanged,
	},
	engineHandlers ={ 
		onFrame = onFrame,
		onUpdate = onUpdate,
		onLoad = onLoad,
		onSave = onSave,
		onInit = onInit,
	}
}