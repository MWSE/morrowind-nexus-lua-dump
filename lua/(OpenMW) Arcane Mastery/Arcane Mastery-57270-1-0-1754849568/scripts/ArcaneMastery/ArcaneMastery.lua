local core = require('openmw.core')
local util = require('openmw.util')
local self = require('openmw.self')
local async = require('openmw.async')
local types = require('openmw.types')
local ui = require('openmw.ui')
local Player = require('openmw.types').Player
local actorSpells = types.Actor.spells(self)

local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerPage({
   key = "arcanemastery",
   l10n = "ArcaneMastery",
   name = "settings_modName",
   description = "settings_modDesc",
})

local skillAlchemy = 0
local skillAlteration = 0
local skillConjuration = 0
local skillDestruction = 0
local skillEnchant = 0
local skillIllusion = 0
local skillMysticism = 0
local skillRestoration = 0
local skillUnarmored = 0

local needsUpdating = true

local currentBonusX1 = 0
local previousBonusX1 = 0
local currentBonusX10 = 0
local previousBonusX10 = 0
local currentSkillScore = 0

local playerIsApprentice = false
local playerIsAtronach = false
local playerIsMage = false
local playerIsAltmer = false
local playerIsBreton = false
local playerCheckComplete = false

local masteryPowersX1 = {'arcane mastery 1', 'arcane mastery 2', 'arcane mastery 3', 'arcane mastery 4', 'arcane mastery 5', 'arcane mastery 6', 'arcane mastery 7', 'arcane mastery 8', 'arcane mastery 9' }
local masteryPowersX10 = {'arcane mastery 10', 'arcane mastery 20', 'arcane mastery 30', 'arcane mastery 40', 'arcane mastery 50', 'arcane mastery 60', 'arcane mastery 70', 'arcane mastery 80', 'arcane mastery 90', 'arcane mastery 100' }


local   settingIncludeAlchemy
local 	settingIncludeEnchant
local 	settingIncludeUnarmored
local 	settingUseModified
local 	settingBretonSkillModifier
local 	settingAltmerSkillModifier
local 	settingMageSkillModifier
local 	settingApprenticeSkillModifier
local 	settingAtronachSkillModifier
local 	settingBretonCapModifier
local 	settingAltmerCapModifier
local 	settingMageCapModifier
local 	settingApprenticeCapModifier
local 	settingAtronachCapModifier
local 	settingMinimumSkillLevel
local 	settingSkillPointsPer1Bonus
local 	settingBonusCap
local 	settingSkillCap

I.Settings.registerGroup({
   key = "Settings_arcanemastery",
   page = "arcanemastery",
   l10n = "ArcaneMastery",
   name = "settings_modCat1_name",
   permanentStorage = true,
   settings = {
      {
         key = "useModifiedSkills",
         name = "settings_modCat1_setting01_name",
		 description = "settings_modCat1_setting01_desc",
         default = true,
         renderer = "checkbox",
      },
	  {
         key = "includeAlchemy",
         name = "settings_modCat1_setting02_name",
         default = false,
         renderer = "checkbox",
      },
	  {
         key = "includeEnchant",
         name = "settings_modCat1_setting03_name",
         default = false,
         renderer = "checkbox",
      },
	  {
         key = "includeUnarmored",
         name = "settings_modCat1_setting04_name",
         default = false,
         renderer = "checkbox",
      },
	  {
         key = "minimumSkillLevel",
         name = "settings_modCat1_setting05_name",
		 description = "settings_modCat1_setting05_desc",
         default = 5,
         renderer = "number",
         argument = { min = 0, max = 100 },
      },
	  {
         key = "skillPointsPer1Bonus",
         name = "settings_modCat1_setting06_name",
		 description = "settings_modCat1_setting06_desc",
         default = 10,
         renderer = "number",
         argument = { min = 1, max = 100 },
      },
	  {
         key = "skillCap",
         name = "settings_modCat1_setting07_name",
		 description = "settings_modCat1_setting07_desc",
         default = 100,
         renderer = "number",
         argument = { min = 1, max = 1000 },
      },
	  {
         key = "bonusCap",
         name = "settings_modCat1_setting08_name",
		 description = "settings_modCat1_setting08_desc",
         default = 100,
         renderer = "number",
         argument = { min = 1, max = 100 },
      },
      {
         key = "altmerSkillModifier",
         name = "settings_modCat1_setting09_name",
		 description = "settings_modCat1_setting09_desc",
         default = 0,
         renderer = "number",
         argument = { min = -100, max = 100 },
      },  
	  {
         key = "bretonSkillModifier",
         name = "settings_modCat1_setting10_name",
         default = 0,
         renderer = "number",
         argument = { min = -100, max = 100 },
      },
	  {
         key = "apprenticeSkillModifier",
         name = "settings_modCat1_setting11_name",
         default = 0,
         renderer = "number",
         argument = { min = -100, max = 100 },
      },
	  {
         key = "atronachSkillModifier",
         name = "settings_modCat1_setting12_name",
         default = 0,
         renderer = "number",
         argument = { min = -100, max = 100 },
      },
	  {
         key = "mageSkillModifier",
         name = "settings_modCat1_setting13_name",
         default = 0,
         renderer = "number",
         argument = { min = -100, max = 100 },
      },
	  {
         key = "altmerCapModifier",
         name = "settings_modCat1_setting14_name",
		 description = "settings_modCat1_setting14_desc",
         default = -15,
         renderer = "number",
         argument = { min = -100, max = 100 },
      },
	  {
         key = "bretonCapModifier",
         name = "settings_modCat1_setting15_name",
         default = -5,
         renderer = "number",
         argument = { min = -100, max = 100 },
      },
	  {
         key = "apprenticeCapModifier",
         name = "settings_modCat1_setting16_name",
         default = -15,
         renderer = "number",
         argument = { min = -100, max = 100 },
      },
	  {
         key = "atronachCapModifier",
         name = "settings_modCat1_setting17_name",
         default = -20,
         renderer = "number",
         argument = { min = -100, max = 100 },
      },
	  {
         key = "mageCapModifier",
         name = "settings_modCat1_setting18_name",
         default = -5,
         renderer = "number",
         argument = { min = -100, max = 100 },
      },
   },
})

local playerSettings = storage.playerSection('Settings_arcanemastery')

local function updateSettings()
settingIncludeAlchemy = playerSettings:get('includeAlchemy')
settingIncludeEnchant = playerSettings:get('includeEnchant')
settingIncludeUnarmored = playerSettings:get('includeUnarmored')
settingUseModified = playerSettings:get('useModifiedSkills')
settingBretonSkillModifier = playerSettings:get('bretonSkillModifier')
settingAltmerSkillModifier = playerSettings:get('altmerSkillModifier')
settingMageSkillModifier = playerSettings:get('mageSkillModifier')
settingApprenticeSkillModifier = playerSettings:get('apprenticeSkillModifier')
settingAtronachSkillModifier = playerSettings:get('atronachSkillModifier')
settingBretonCapModifier = playerSettings:get('bretonCapModifier')
settingAltmerCapModifier = playerSettings:get('altmerCapModifier')
settingMageCapModifier = playerSettings:get('mageCapModifier')
settingApprenticeCapModifier = playerSettings:get('apprenticeCapModifier')
settingAtronachCapModifier = playerSettings:get('atronachCapModifier')
settingMinimumSkillLevel = playerSettings:get('minimumSkillLevel')
settingSkillPointsPer1Bonus = playerSettings:get('skillPointsPer1Bonus')
settingBonusCap = playerSettings:get('bonusCap')
settingSkillCap = playerSettings:get('skillCap')
needsUpdating = true
end

local function init()
	updateSettings()
end

playerSettings:subscribe(async:callback(updateSettings))


local function doStuff()
	
	local statsChanged = false
	local tempSkill = 0
	local score = 0
	local scoreChanged = false
	local masteryLevel = 0
	local masteryChangedX1 = false
	local masteryChangedX10 = false
	local playerSkillModifier = 0
	local playerCapModifier = 0
	
	if Player.isCharGenFinished(self) then
	
	if playerCheckComplete == false or needsUpdating  then
		if needsUpdating  then print("Settings updated. Recalculating...") end
		if types.Player.getBirthSign(self) == 'elfborn' then
			playerIsApprentice = true
			print("Player is Apprentice.")
		end
		if types.Player.getBirthSign(self) == 'wombburned' then
			playerIsAtronach = true
			print("Player is Atronach.")
		end
		if types.Player.getBirthSign(self) == 'fay' then
			playerIsMage = true
			print("Player is Mage.")
		end
		if types.NPC.record(self).race == 'breton' then
			playerIsBreton = true
			print("Player is Breton.")
		end
		if types.NPC.record(self).race == 'high elf' or types.NPC.record(self).race == 'altmer' then
			playerIsAltmer = true
			print("Player is Altmer.")
		end
		playerCheckComplete = true
		
	end
	
	if settingUseModified then
		if settingIncludeAlchemy then
			tempSkill = types.NPC.stats.skills.alchemy(self).modified
			if tempSkill ~= skillAlchemy then
				statsChanged = true
				print("Alchemy skill level has changed.")
				skillAlchemy = tempSkill
			end
		end
		if settingIncludeEnchant then
			tempSkill = types.NPC.stats.skills.enchant(self).modified
			if tempSkill ~= skillEnchant then
				statsChanged = true
				print("Enchant skill level has changed.")
				skillEnchant = tempSkill
			end
		end
		if settingIncludeUnarmored then
			tempSkill = types.NPC.stats.skills.unarmored(self).modified
			if tempSkill ~= skillUnarmored then
				statsChanged = true
				print("Unarmored skill level has changed.")
				skillUnarmored = tempSkill
			end
		end
		tempSkill = types.NPC.stats.skills.alteration(self).modified
		if tempSkill ~= skillAlteration then
			statsChanged = true
			print("Alteration skill level has changed.")
			skillAlteration = tempSkill
		end
	
		tempSkill = types.NPC.stats.skills.conjuration(self).modified
		if tempSkill ~= skillConjuration then
			statsChanged = true
			print("Conjuration skill level has changed.")
			skillConjuration = tempSkill
		end
	
		tempSkill = types.NPC.stats.skills.destruction(self).modified
		if tempSkill ~= skillDestruction then
			statsChanged = true
			print("Destruction skill level has changed.")
			skillDestruction = tempSkill
		end
	
		tempSkill = types.NPC.stats.skills.illusion(self).modified
		if tempSkill ~= skillIllusion then
			statsChanged = true
			print("Illusion skill level has changed.")
			skillIllusion = tempSkill
		end
		
		tempSkill = types.NPC.stats.skills.mysticism(self).modified
		if tempSkill ~= skillMysticism then
			statsChanged = true
			print("Mysticism skill level has changed.")
			skillMysticism = tempSkill
		end	
	
		tempSkill = types.NPC.stats.skills.restoration(self).modified
		if tempSkill ~= skillRestoration then
			statsChanged = true
			print("Restoration skill level has changed.")
			skillRestoration = tempSkill
		end
	
	else
	
		if settingIncludeAlchemy then
			tempSkill = types.NPC.stats.skills.alchemy(self).base
			if tempSkill ~= skillAlchemy then
				statsChanged = true
				print("Alchemy skill level has changed.")
				skillAlchemy = tempSkill
			end
		end
		
		if settingIncludeEnchant then
			tempSkill = types.NPC.stats.skills.enchant(self).base
			if tempSkill ~= skillEnchant then
				statsChanged = true
				print("Enchant skill level has changed.")
				skillEnchant = tempSkill
			end
		end
		
		if settingIncludeUnarmored then
			tempSkill = types.NPC.stats.skills.unarmored(self).base
			if tempSkill ~= skillUnarmored then
				statsChanged = true
				print("Unarmored skill level has changed.")
				skillUnarmored = tempSkill
			end
		end
		
		tempSkill = types.NPC.stats.skills.alteration(self).base
			if tempSkill ~= skillAlteration then
				statsChanged = true
				print("Alteration skill level has changed.")
				skillAlteration = tempSkill
			end
		
		tempSkill = types.NPC.stats.skills.conjuration(self).base
			if tempSkill ~= skillConjuration then
				statsChanged = true
				print("Conjuration skill level has changed.")
				skillConjuration = tempSkill
			end
		
		tempSkill = types.NPC.stats.skills.destruction(self).base
			if tempSkill ~= skillDestruction then
				statsChanged = true
				print("Destruction skill level has changed.")
				skillDestruction = tempSkill
			end
		
		tempSkill = types.NPC.stats.skills.illusion(self).base
			if tempSkill ~= skillIllusion then
				statsChanged = true
				print("Illusion skill level has changed.")
				skillIllusion = tempSkill
			end
			
		tempSkill = types.NPC.stats.skills.mysticism(self).base
			if tempSkill ~= skillMysticism then
				statsChanged = true
				print("Mysticism skill level has changed.")
				skillMysticism = tempSkill
			end	
		
		tempSkill = types.NPC.stats.skills.restoration(self).base
			if tempSkill ~= skillRestoration then
				statsChanged = true
				print("Restoration skill level has changed.")
				skillRestoration = tempSkill
			end
	end
	
	if statsChanged or needsUpdating then
		print("Recalculating skill score.")
		if settingIncludeAlchemy then score = score + math.min(settingSkillCap , math.max(0, skillAlchemy - settingMinimumSkillLevel)) end
		if settingIncludeEnchant then score = score + math.min(settingSkillCap , math.max(0, skillEnchant - settingMinimumSkillLevel)) end
		if settingIncludeUnarmored then score = score + math.min(settingSkillCap , math.max(0, skillUnarmored - settingMinimumSkillLevel)) end
		score = score + math.min(settingSkillCap , math.max(0, skillAlteration - settingMinimumSkillLevel))
		score = score + math.min(settingSkillCap , math.max(0, skillConjuration - settingMinimumSkillLevel))
		score = score + math.min(settingSkillCap , math.max(0, skillDestruction - settingMinimumSkillLevel))
		score = score + math.min(settingSkillCap , math.max(0, skillIllusion - settingMinimumSkillLevel))
		score = score + math.min(settingSkillCap , math.max(0, skillMysticism - settingMinimumSkillLevel))
		score = score + math.min(settingSkillCap , math.max(0, skillRestoration - settingMinimumSkillLevel))
		if score ~= currentSkillScore then
			currentSkillScore = score
			scoreChanged = true
			print("Skill score has changed. Recalculating bonuses. Current score: " .. currentSkillScore)
		else
			print("Skill score hasn't changed. Current score: " .. currentSkillScore)
		end
	end
	
	if scoreChanged or needsUpdating then
	
		if playerIsAltmer  then 
			playerSkillModifier = playerSkillModifier + settingAltmerSkillModifier
			playerCapModifier = playerCapModifier + settingAltmerCapModifier
		end
		if playerIsBreton  then
			playerSkillModifier = playerSkillModifier + settingBretonSkillModifier
			playerCapModifier = playerCapModifier + settingBretonCapModifier
		end
		if playerIsApprentice  then
			playerSkillModifier = playerSkillModifier + settingApprenticeSkillModifier
			playerCapModifier = playerCapModifier + settingApprenticeCapModifier
		end
		if playerIsAtronach  then
			playerSkillModifier = playerSkillModifier + settingAtronachSkillModifier
			playerCapModifier = playerCapModifier + settingAtronachCapModifier
		end
		if playerIsMage  then
			playerSkillModifier = playerSkillModifier + settingMageSkillModifier
			playerCapModifier = playerCapModifier + settingMageCapModifier
		end
		
		print("Total skill modifier: " .. playerSkillModifier)
		print("Total cap modifier: " .. playerCapModifier)
								
	
		masteryLevel = math.min(math.floor(currentSkillScore / math.max((settingSkillPointsPer1Bonus + playerSkillModifier), 1)) , settingBonusCap + playerCapModifier)
		if math.floor(masteryLevel / 10) ~= currentBonusX10 then
			previousBonusX10 = currentBonusX10
			currentBonusX10 = math.floor(masteryLevel / 10)
			masteryChangedX10 = true
		end
		if (masteryLevel % 10) ~= currentBonusX1 then
			previousBonusX1 = currentBonusX1
			currentBonusX1 = masteryLevel % 10
			masteryChangedX1 = true
	end
	
	if masteryChangedX1  then
		if currentBonusX1 ~= 0 then
			actorSpells:add(masteryPowersX1[currentBonusX1])
			print("Added power level " .. currentBonusX1)
		end
		if previousBonusX1 ~= 0 and previousBonusX1 ~= nil then
			actorSpells:remove(masteryPowersX1[previousBonusX1])
			print("Removed power level " .. previousBonusX1)
		end	
	end
	
	if masteryChangedX10  then
		if currentBonusX10 ~= 0 then
			actorSpells:add(masteryPowersX10[math.min(10, currentBonusX10)])
			print("Added power level: " .. currentBonusX10 .. "0")
		end
		if previousBonusX10 ~= 0 and previousBonusX10 ~= nil then
			actorSpells:remove(masteryPowersX10[math.min(10, previousBonusX10)])
			print("Removed power level: " .. previousBonusX10 .. "0")
		end		
	end
	
end
needsUpdating = false
end
end


local function onSave()
	return {
	--skillAlchemy = skillAlchemy,
	--skillAlteration = skillAlteration,
	--skillConjuration = skillConjuration,
	--skillDestruction = skillDestruction,
	--skillEnchant = skillEnchant,
	--skillIllusion = skillIllusion,
	--skillMysticism = skillMysticism,
	--skillRestoration = skillRestoration,
	--skillUnarmored = skillUnarmored,
	currentBonusX1 = currentBonusX1,
	previousBonusX1 = previousBonusX1,
	currentBonusX10 = currentBonusX10,
	previousBonusX10 = previousBonusX10,
	currentSkillScore = currentSkillScore
	}
end

local function onLoad(data)
	if data then
	--	skillAlchemy = data.skillAlchemy
	--	skillAlteration = data.skillAlteration
	--	skillConjuration = data.skillConjuration
	--	skillDestruction = data.skillDestruction
	--	skillEnchant = data.skillEnchant
	--	skillIllusion = data.skillIllusion
	--	skillMysticism = data.skillMysticism
	--	skillRestoration = data.skillRestoration
	--	skillUnarmored = data.skillUnarmored
		currentBonusX1 = data.currentBonusX1
		previousBonusX1 = data.previousBonusX1
		currentBonusX10 = data.currentBonusX10
		previousBonusX10 = data.previousBonusX10
		currentSkillScore = data.currentSkillScore
	end
	init()
end

return {
    engineHandlers = {
		onInit = init,
        onUpdate = doStuff,
        onSave = onSave,
        onLoad = onLoad,
	--	onKeyPress = function(key)
           -- if key.symbol == 'x' then
                --ui.showMessage("Race: " .. types.NPC.record(self).race)
				--ui.showMessage('Current skill score: '.. currentSkillScore .. " Current bonuses: " .. currentBonusX10 .. "0+" .. currentBonusX1 )
				
      --      end
      --  end
    }
}