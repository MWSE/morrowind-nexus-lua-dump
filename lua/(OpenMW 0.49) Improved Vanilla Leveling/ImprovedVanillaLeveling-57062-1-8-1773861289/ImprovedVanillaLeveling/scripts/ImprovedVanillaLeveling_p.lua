local ui = require('openmw.ui')
I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local Player = require('openmw.types').Player
local core = require('openmw.core')
local self = require('openmw.self')
MODNAME = "ImprovedVanillaLeveling"
local storage = require('openmw.storage')
playerSection = storage.playerSection('SettingsPlayer'..MODNAME)
local s = require("scripts.ImprovedVanillaLeveling_settings")

attributeList = {
    endurance = {
        "heavyarmor",
        "mediumarmor",
        "spear"
    },
    strength = {
        "acrobatics",
        "armorer",
        "axe",
        "bluntweapon",
        "longblade"
    },
    agility = {
        "block",
        "lightarmor",
        "marksman",
        "sneak"
    },
    speed = {
        "athletics",
        "handtohand",
        "shortblade",
        "unarmored"
    },
    personality = {
        "illusion",
        "mercantile",
        "speechcraft"
    },
    intelligence = {
        "alchemy",
        "conjuration",
        "enchant",
        "security"
    },
    willpower = {
        "alteration",
        "destruction",
        "mysticism",
        "restoration"
    },
	luck = {}
}

local function getAttributes()
	local attributes = {}
	for att in pairs(attributeList) do
		attributes[att] = types.NPC.stats.attributes[att](self).base
	end
	return attributes
end

local levelUpPoints = {0}
local points = 1
for i = 1, 10 do
	local gmst = core.getGMST("iLevelUp"..string.format("%02d", i).."Mult")
	if not levelUpPoints[gmst] then
		levelUpPoints[gmst] = i
	end
end

local function getSkillIncreasesForAttribute()
    local levelStats = types.Actor.stats.level(self)
    return {
        agility = levelStats.skillIncreasesForAttribute.agility,
        endurance = levelStats.skillIncreasesForAttribute.endurance,
        intelligence = levelStats.skillIncreasesForAttribute.intelligence,
        luck = levelStats.skillIncreasesForAttribute.luck,
        personality =  types.Actor.stats.level(self).skillIncreasesForAttribute.personality,
        speed = levelStats.skillIncreasesForAttribute.speed,
        strength = levelStats.skillIncreasesForAttribute.strength,
        willpower = levelStats.skillIncreasesForAttribute.willpower
    }
end

local function UiModeChanged(data)
	--I.SkillProgression.skillLevelUp("longblade", I.SkillProgression.SKILL_INCREASE_SOURCES.Book)
	if data.newMode == "LevelUp" then
		level = types.Actor.stats.level(self).current
		skillIncreasesForAttribute = getSkillIncreasesForAttribute()
		for a,b in pairs(skillIncreasesForAttribute) do
			print(a,b)
		end
		progress = types.Actor.stats.level(self).progress
		attributes = getAttributes()
	elseif data.oldMode == "LevelUp" then
		local newLevel = types.Actor.stats.level(self).current
		if newLevel > level then
			level = newLevel
			progress = types.Actor.stats.level(self).progress
			local newAttributes = getAttributes()
			if playerSection:get("keepAttributeProgress") then
				attributeIncreases = {}
				for a,b in pairs(newAttributes) do
					attributeIncreases[a] = b-attributes[a]
					if attributeIncreases[a] == 0 then
						attributeIncreases[a] = nil
					end
				end
				for att, lv in pairs(attributeIncreases) do
					skillIncreasesForAttribute[att] = math.max(0,skillIncreasesForAttribute[att] - levelUpPoints[lv])
				end
				--local clearSpam = false
				for att, incs in pairs(skillIncreasesForAttribute) do
					if newAttributes[att] >= 100 and playerSection:get("capAt100") then
						-- do nothing
					else
						types.Actor.stats.level(self).skillIncreasesForAttribute[att] = math.max(types.Actor.stats.level(self).skillIncreasesForAttribute[att],incs)
						print(att, incs)
					end
				end
			end
			if playerSection:get("retroactiveHealth") then
				local fLevelUpHealthEndMult = core.getGMST("fLevelUpHealthEndMult")
				local oldHealthPerLevel = (attributes.endurance * fLevelUpHealthEndMult)
				local newHealthPerLevel = (newAttributes.endurance * fLevelUpHealthEndMult)
				local missedHealthPerLevel = newHealthPerLevel - oldHealthPerLevel
				local missedHealth = missedHealthPerLevel * (level-2)
				if missedHealth > 0 then
					print("Retroactively adding health: "..string.format("%.02f", types.Actor.stats.dynamic.health(self).base).." -> "..string.format("%.02f", (types.Actor.stats.dynamic.health(self).base + missedHealth)))
					types.Actor.stats.dynamic.health(self).base = types.Actor.stats.dynamic.health(self).base + missedHealth
				end
			end
			--types.Actor.stats.level(self).progress = progress
		end
	end
end

local Templates = I.StatsWindow and I.StatsWindow.Templates.STATS

if Templates then
	Templates.levelTooltip = function()
		local level = self.type.stats.level(self)
		local skillUpsPerLevel = core.getGMST('iLevelupTotal')
		local attrUps = level.skillIncreasesForAttribute
		local actualAttrUps = {}
		local levelUpMults = {
			[1] = core.getGMST('iLevelUp01Mult'),
			[2] = core.getGMST('iLevelUp02Mult'),
			[3] = core.getGMST('iLevelUp03Mult'),
			[4] = core.getGMST('iLevelUp04Mult'),
			[5] = core.getGMST('iLevelUp05Mult'),
			[6] = core.getGMST('iLevelUp06Mult'),
			[7] = core.getGMST('iLevelUp07Mult'),
			[8] = core.getGMST('iLevelUp08Mult'),
			[9] = core.getGMST('iLevelUp09Mult'),
			[10] = core.getGMST('iLevelUp10Mult'),
		}
		local showSkillIncreases = playerSection:get("showSkillIncreases")
		local showOverflowAttributeIncreases = playerSection:get("showOverflowAttributeIncreases")
		for _, attr in ipairs(core.stats.Attribute.records) do
			if attrUps[attr.id] and attrUps[attr.id] > 0 then
				local mult = levelUpMults[math.min(attrUps[attr.id], 10)]
				if mult > 0 then
					actualAttrUps[attr.id] = mult
					if attrUps[attr.id] > 10 then
						local overflow = attrUps[attr.id] - 10
						local overflowAttributePoints = 0
						while overflow > 0 do
							overflowAttributePoints = overflowAttributePoints + levelUpMults[math.min(overflow, 10)]
							overflow = overflow - 10
						end
						if overflowAttributePoints > 0 and showOverflowAttributeIncreases then
							actualAttrUps[attr.id] = actualAttrUps[attr.id] .. " + x" .. overflowAttributePoints
						end
					end
					if showSkillIncreases then
						actualAttrUps[attr.id] = actualAttrUps[attr.id] .. " #dfc99f("..attrUps[attr.id]..")"
					end
				end
			end
		end
		return Templates.tooltip(8, Templates.levelProgressBar(level.progress, skillUpsPerLevel, actualAttrUps), 'level')
	end
end


return {
	engineHandlers = { 
	},
	eventHandlers = { 
		UiModeChanged = UiModeChanged,
	}
}