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
local currentFFMag, previousMaxFat, previousCurFat

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

local function onAtrChange(newAtr, newFFMag)
    common.logMsg(fatCap, "Either a fatigue-related attribute has changed, or interop.recalc.fatigue has been set to true by another mod.")

    for i = 1, #fatAttributes do
        local atrId = fatAttributes[i]
        local atrName = tes3.attributeName[atrId]
        common.logMsg(fatCap, string.format("Old %s: %f", atrName, currentAtr[atrId]))
        common.logMsg(fatCap, string.format("New %s: %f", atrName, newAtr[atrId]))
    end

    common.onAtrChange(fat, newFFMag, currentFFMag, previousMaxFat, previousCurFat)

    for i = 1, #fatAttributes do
        local id = fatAttributes[i]
        currentAtr[id] = newAtr[id]
    end

    currentFFMag = newFFMag
end

function this.onEnterFrame()
    if not tes3.player then
        return
    end

    local newAtr = getAttributes()
    local newFFMag = common.getEffectMag(tes3.effect.fortifyFatigue)

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
        onAtrChange(newAtr, newFFMag)
    elseif newFFMag ~= currentFFMag then
        common.onFortChange(fat, newFFMag, currentFFMag)
        currentFFMag = newFFMag
    end

    previousMaxFat, previousCurFat = common.recordStat(fat)
end

function this.onLoaded()
    currentAtr = getAttributes()
    currentFFMag = common.getEffectMag(tes3.effect.fortifyFatigue)

    common.onLoaded(fat, currentFFMag)

    previousMaxFat, previousCurFat = common.recordStat(fat)
end

return this