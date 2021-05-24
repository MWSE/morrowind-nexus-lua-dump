local this = {}
local common = require("FortifyMAX.common")
local interop = require("FortifyMAX.interop")

local mag = "magicka"
local magCap = string.gsub(mag, "%l", string.upper, 1)

local currentInt, currentMagickaMultiplier, currentFMMag, previousMaxMag, previousCurMag

local function onIntChange(newInt, newMagickaMultiplier, newFMMag)
    common.logMsg(magCap, "Either intelligence or magicka multiplier has changed, or interop.recalc.magicka has been set to true by another mod.")
    common.logMsg(magCap, string.format("Old intelligence: %f", currentInt))
    common.logMsg(magCap, string.format("Old magicka multiplier: %f", currentMagickaMultiplier))
    common.logMsg(magCap, string.format("New intelligence: %f", newInt))
    common.logMsg(magCap, string.format("New magicka multiplier: %f", newMagickaMultiplier))

    common.onAtrChange(mag, newFMMag, currentFMMag, previousMaxMag, previousCurMag)

    currentInt = newInt
    currentMagickaMultiplier = newMagickaMultiplier
    currentFMMag = newFMMag
end

function this.onEnterFrame()
    if not tes3.player then
        return
    end

    --[[ .currentRaw is usually the same as .current. But when the current value of an attribute is negative, .current
    will return 0, while .currentRaw will return the actual (negative) value. Checking .currentRaw here allows us to
    catch when the game recalculates magicka under certain circumstances, such as when intelligence is damaged to 0 and
    then is drained further (or a Fortify Intelligence effect expires). ]]--
    local newInt = tes3.mobilePlayer.intelligence.currentRaw
    local newMagickaMultiplier = tes3.mobilePlayer.magickaMultiplier.current
    local newFMMag = common.getEffectMag(tes3.effect.fortifyMagicka)

    if newInt ~= currentInt
    or newMagickaMultiplier ~= currentMagickaMultiplier
    or interop.recalc.magicka then
        onIntChange(newInt, newMagickaMultiplier, newFMMag)
    elseif newFMMag ~= currentFMMag then
        common.onFortChange(mag, newFMMag, currentFMMag)
        currentFMMag = newFMMag
    end

    -- We need to keep track of max and current magicka every frame - this information is needed for the mod to
    -- determine the correct magicka ratio to maintain when intelligence changes and the player is under a Fortify
    -- Magicka effect.
    previousMaxMag, previousCurMag = common.recordStat(mag)
end

function this.onLoaded()
    currentInt = tes3.mobilePlayer.intelligence.currentRaw
    currentMagickaMultiplier = tes3.mobilePlayer.magickaMultiplier.current
    currentFMMag = common.getEffectMag(tes3.effect.fortifyMagicka)

    common.onLoaded(mag, currentFMMag)

    previousMaxMag, previousCurMag = common.recordStat(mag)
end

return this