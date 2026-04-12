LOCK_CAP_TABLE = false -- true = settings cannot override these values

capTable = {
	-- Skills
	["acrobatics"]   = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["alchemy"]      = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["alteration"]   = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["armorer"]      = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["athletics"]    = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["axe"]          = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["block"]        = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["bluntweapon"]  = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["conjuration"]  = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["destruction"]  = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["enchant"]      = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["handtohand"]   = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["heavyarmor"]   = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["illusion"]     = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["lightarmor"]   = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["longblade"]    = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["marksman"]     = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["mediumarmor"]  = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["mercantile"]   = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["mysticism"]    = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["restoration"]  = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["security"]     = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["shortblade"]   = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["sneak"]        = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["spear"]        = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["speechcraft"]  = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	["unarmored"]    = { softCap = 100, xpMultAtSoftCap = 0.5, hardCap = 200 },
	-- Attributes
	["agility"]      = { softCap = 100, maxGainsPerLevel = 2, neededSkillIncMult = 2, neededSkillIncFlat = 0, hardCap = 200 },
	["endurance"]    = { softCap = 100, maxGainsPerLevel = 1, neededSkillIncMult = 3, neededSkillIncFlat = 0, hardCap = 150 },
	["intelligence"] = { softCap = 100, maxGainsPerLevel = 2, neededSkillIncMult = 2, neededSkillIncFlat = 0, hardCap = 200 },
	["luck"]         = { softCap = 100, maxGainsPerLevel = 2, neededSkillIncMult = 2, neededSkillIncFlat = 0, hardCap = 200 },
	["personality"]  = { softCap = 100, maxGainsPerLevel = 2, neededSkillIncMult = 2, neededSkillIncFlat = 0, hardCap = 200 },
	["speed"]        = { softCap = 100, maxGainsPerLevel = 2, neededSkillIncMult = 2, neededSkillIncFlat = 0, hardCap = 200 },
	["strength"]     = { softCap = 100, maxGainsPerLevel = 2, neededSkillIncMult = 2, neededSkillIncFlat = 0, hardCap = 200 },
	["willpower"]    = { softCap = 100, maxGainsPerLevel = 2, neededSkillIncMult = 2, neededSkillIncFlat = 0, hardCap = 200 },
}

function applyCapsFromSettings()
	if LOCK_CAP_TABLE then return end
	for id, entry in pairs(capTable) do
		if entry.xpMultAtSoftCap ~= nil then
			-- skill entry
			entry.softCap = S_skillSoftCap
			entry.xpMultAtSoftCap = S_skillXPMultAtSoftCap
			entry.hardCap = S_skillHardCap
		else
			-- attribute entry
			entry.softCap = S_attrSoftCap
			entry.maxGainsPerLevel = S_attrMaxGainsPerLevel
			entry.neededSkillIncMult = S_attrNeededSkillIncMult
			if S_attrNeededSkillIncMult > 1 then
				entry.neededSkillIncFlat = 1
			else
				entry.neededSkillIncFlat = 0
			end
			entry.hardCap = S_attrHardCap
		end
	end
	if S_HarderEndurance then
		capTable.endurance.softCap = math.floor((capTable.endurance.softCap + 100)/2)
		capTable.endurance.maxGainsPerLevel = math.floor(capTable.endurance.maxGainsPerLevel/2 + 0.5)
		capTable.endurance.neededSkillIncFlat = math.max(capTable.endurance.neededSkillIncFlat, 1)
		capTable.endurance.neededSkillIncMult = capTable.endurance.neededSkillIncMult * 1.5
	end
end
