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
        personality = levelStats.skillIncreasesForAttribute.personality,
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
				local clearSpam = false
				for att, incs in pairs(skillIncreasesForAttribute) do
					if newAttributes[att] >= 100 and playerSection:get("cappedAt100") then
						-- do nothing
					else
						for i=1, incs do
							local suitableSkill = nil
							for _, skill in pairs(attributeList[att]) do
								if types.NPC.stats.skills[skill](self).base < 100 then
									suitableSkill = skill
								end
							end
							--suitableSkill = suitableSkill or attributeList[att][1]
							if suitableSkill then -- nil for luck
								--print(suitableSkill,types.NPC.stats.skills[suitableSkill](self).base)
								local oldSkill = types.NPC.stats.skills[suitableSkill](self).base
								print("dummy skill up "..attributeList[att][1].." "..oldSkill)
								I.SkillProgression.skillLevelUp(suitableSkill, I.SkillProgression.SKILL_INCREASE_SOURCES.Book)
								clearSpam = true
								types.NPC.stats.skills[suitableSkill](self).base = oldSkill
							elseif attributeList[att][1] then
								local oldSkill = types.NPC.stats.skills[attributeList[att][1]](self).base
								types.NPC.stats.skills[attributeList[att][1]](self).base = 99
								print("dummy skill up "..attributeList[att][1].." "..oldSkill)
								I.SkillProgression.skillLevelUp(attributeList[att][1], I.SkillProgression.SKILL_INCREASE_SOURCES.Book)
								clearSpam = true
								types.NPC.stats.skills[attributeList[att][1]](self).base = oldSkill
							end
						end
					end
				end
				if clearSpam then
					ui.showMessage("")
					ui.showMessage("")
					ui.showMessage("")
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
			types.Actor.stats.level(self).progress = progress
		end
	end
end




return {
	engineHandlers = { 
	},
	eventHandlers = { 
		UiModeChanged = UiModeChanged,
	}
}