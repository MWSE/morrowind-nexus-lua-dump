-- water_slowdown.lua (v6 – speed + athletics + acrobatics penalties)
local self  = require('openmw.self')
local types = require('openmw.types')

local ANKLE_DEPTH = 10
local KNEE_DEPTH  = 45
local WAIST_DEPTH = 80
local CHEST_DEPTH = 100
local NECK_DEPTH  = 117

local PENALTY_ANKLE = 0.20
local PENALTY_KNEE  = 0.60
local PENALTY_WAIST = 0.80
local PENALTY_CHEST = 1.00   
local PENALTY_NECK  = 0.00

local appliedSpeedMod      = 0
local appliedAthleticsMod  = 0
local appliedAcrobaticsMod = 0

local function setStatModifier(getStat, oldMod, newMod)
    if newMod == oldMod then return oldMod end
    local stat = getStat()
    stat.modifier = stat.modifier - oldMod + newMod
    return newMod
end

local function applyPenalties(penaltyFraction)
    local speedStat      = function() return types.Actor.stats.attributes.speed(self) end
    local athleticsStat  = function() return types.NPC.stats.skills.athletics(self) end
    local acrobaticsStat = function() return types.NPC.stats.skills.acrobatics(self) end

    local baseSpeed      = types.Actor.stats.attributes.speed(self).base
    local baseAthletics  = types.NPC.stats.skills.athletics(self).base
    local baseAcrobatics = types.NPC.stats.skills.acrobatics(self).base

    local newSpeedMod      = -math.floor(baseSpeed      * penaltyFraction)
    local newAthleticsMod  = -math.floor(baseAthletics  * penaltyFraction)
    local newAcrobaticsMod = -math.floor(baseAcrobatics * penaltyFraction)

    appliedSpeedMod      = setStatModifier(speedStat,      appliedSpeedMod,      newSpeedMod)
    appliedAthleticsMod  = setStatModifier(athleticsStat,  appliedAthleticsMod,  newAthleticsMod)
    appliedAcrobaticsMod = setStatModifier(acrobaticsStat, appliedAcrobaticsMod, newAcrobaticsMod)
end

local function clearPenalties()
    applyPenalties(0)
end

local function onUpdate(_dt)
    local cell = self.cell
    if cell == nil then
        clearPenalties()
        return
    end

    local waterSurface = cell.waterLevel
    if waterSurface == nil then
        clearPenalties()
        return
    end

    local immersion = waterSurface - self.position.z

    local penaltyFraction
    if immersion >= NECK_DEPTH then 
		penaltyFraction = PENALTY_NECK	
	elseif immersion >= CHEST_DEPTH then
        penaltyFraction = PENALTY_CHEST
    elseif immersion >= WAIST_DEPTH then
        penaltyFraction = PENALTY_WAIST
    elseif immersion >= KNEE_DEPTH then
        penaltyFraction = PENALTY_KNEE
    elseif immersion >= ANKLE_DEPTH then
        penaltyFraction = PENALTY_ANKLE
    else
        penaltyFraction = 0
    end

    applyPenalties(penaltyFraction)
end

local function onSave()
    return {
        appliedSpeedMod      = appliedSpeedMod,
        appliedAthleticsMod  = appliedAthleticsMod,
        appliedAcrobaticsMod = appliedAcrobaticsMod,
    }
end

local function onLoad(data)
    appliedSpeedMod      = (data and data.appliedSpeedMod)      or 0
    appliedAthleticsMod  = (data and data.appliedAthleticsMod)  or 0
    appliedAcrobaticsMod = (data and data.appliedAcrobaticsMod) or 0
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave   = onSave,
        onLoad   = onLoad,
    }
}