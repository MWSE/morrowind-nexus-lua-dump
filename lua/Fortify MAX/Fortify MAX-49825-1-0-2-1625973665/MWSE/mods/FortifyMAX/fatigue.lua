-- See comments in magicka.lua.
local this = {}
local common = require("FortifyMAX.common")
local interop = require("FortifyMAX.interop")

local fat = "fatigue"
local fatCap = string.gsub(fat, "%l", string.upper, 1)

local fatAttributes = {
    tes3.attribute.strength,
    tes3.attribute.willpower,
    tes3.attribute.agility,
    tes3.attribute.endurance,
}

local currentAtr = {}
local currentFFMag, currentTotalFFMag, previousMaxFat, previousCurFat

-- Returns a table with the current strength, willpower, agility and endurance.
local function getAttributes()
    local table = {}

    for i = 1, #fatAttributes do
        local atrId = fatAttributes[i]

        -- The attribute IDs the game uses for mobile actors are off by one from the ones MWSE uses.
        local atrIdMob = atrId + 1
        table[atrId] = tes3.mobilePlayer.attributes[atrIdMob].currentRaw
    end

    return table
end

local function onAtrChange(newAtr, newTotalFFMag)
    common.logMsg(fatCap, "Either a fatigue-related attribute has changed, or interop.recalc.fatigue has been set to true by another mod.")

    for i = 1, #fatAttributes do
        local atrId = fatAttributes[i]
        local atrName = tes3.attributeName[atrId]
        common.logMsg(fatCap, string.format("Old %s: %f", atrName, currentAtr[atrId]))
        common.logMsg(fatCap, string.format("New %s: %f", atrName, newAtr[atrId]))
    end

    common.onAtrChange(fat, newTotalFFMag, currentTotalFFMag, previousMaxFat, previousCurFat)

    for i = 1, #fatAttributes do
        local id = fatAttributes[i]
        currentAtr[id] = newAtr[id]
    end
end

function this.onEnterFrame()
    if not tes3.player then
        return
    end

    local newAtr = getAttributes()
    local newFFMag, newTotalFFMag = common.getEffectMagNoScriptAbl(tes3.effect.fortifyFatigue)

    local atrChanged = false

    for i = 1, #fatAttributes do
        local id = fatAttributes[i]

        if newAtr[id] ~= currentAtr[id] then
            atrChanged = true
            break
        end
    end

    if atrChanged
    or interop.recalc.fatigue then
        onAtrChange(newAtr, newTotalFFMag)
        currentFFMag = newFFMag
    elseif newFFMag ~= currentFFMag then
        common.onFortChange(fat, newFFMag, currentFFMag)
        currentFFMag = newFFMag
    end

    if newTotalFFMag ~= currentTotalFFMag then
        currentTotalFFMag = newTotalFFMag
    end

    previousMaxFat, previousCurFat = common.recordStat(fat)
end

function this.onLoaded()
    currentAtr = getAttributes()
    currentFFMag, currentTotalFFMag = common.getEffectMagNoScriptAbl(tes3.effect.fortifyFatigue)

    common.onLoaded(fat, currentTotalFFMag)

    previousMaxFat, previousCurFat = common.recordStat(fat)
end

return this