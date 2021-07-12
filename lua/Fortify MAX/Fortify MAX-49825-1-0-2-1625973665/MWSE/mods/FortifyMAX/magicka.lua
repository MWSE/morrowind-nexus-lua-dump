local this = {}
local common = require("FortifyMAX.common")
local interop = require("FortifyMAX.interop")

local mag = "magicka"
local magCap = string.gsub(mag, "%l", string.upper, 1)

local currentInt, currentMagickaMultiplier, currentFMMag, currentTotalFMMag, previousMaxMag, previousCurMag

local function onIntChange(newInt, newMagickaMultiplier, newTotalFMMag)
    common.logMsg(magCap, "Either intelligence or magicka multiplier has changed, or interop.recalc.magicka has been set to true by another mod.")
    common.logMsg(magCap, string.format("Old intelligence: %f", currentInt))
    common.logMsg(magCap, string.format("Old magicka multiplier: %f", currentMagickaMultiplier))
    common.logMsg(magCap, string.format("New intelligence: %f", newInt))
    common.logMsg(magCap, string.format("New magicka multiplier: %f", newMagickaMultiplier))

    common.onAtrChange(mag, newTotalFMMag, currentTotalFMMag, previousMaxMag, previousCurMag)

    currentInt = newInt
    currentMagickaMultiplier = newMagickaMultiplier
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

    --[[ We need to keep track of two Fortify Magicka magnitudes every frame. newTotalFMMag is the total magnitude of
    the effect. newFMMag is the total magnitude minus any magnitude that is caused by an ability that is *not* on the
    player's race or birthsign spell list. (These magnitudes are usually the same, unless the player is using a mod that
    adds FM/FF abilities via script.) We need to do this because the game applies FM/FF magnitude from abilities to the
    max stat on its own (although this doesn't work properly in the case of race/birthsign abilities in place at the
    beginning of the game).

    When the magnitude *not* including script-added abilities changes, we send only that magnitude as a parameter to the
    common.onFortChange function, because the game handles any magnitude granted by script-added abilities on its own.
    But when intelligence changes, we send the total magnitude as a param to the onIntChange function, because the
    game's vanilla magicka calculations it does on int change will wipe out the full FM magnitude from max magicka,
    including that given by script-added abilities, and we have to add the full magnitude back (the same is true on
    loaded). ]]--
    local newFMMag, newTotalFMMag = common.getEffectMagNoScriptAbl(tes3.effect.fortifyMagicka)

    if newInt ~= currentInt
    or newMagickaMultiplier ~= currentMagickaMultiplier
    or interop.recalc.magicka then
        onIntChange(newInt, newMagickaMultiplier, newTotalFMMag)
        currentFMMag = newFMMag
    elseif newFMMag ~= currentFMMag then
        common.onFortChange(mag, newFMMag, currentFMMag)
        currentFMMag = newFMMag
    end

    if newTotalFMMag ~= currentTotalFMMag then
        currentTotalFMMag = newTotalFMMag
    end

    -- We need to keep track of max and current magicka every frame - this information is needed for the mod to
    -- determine the correct magicka ratio to maintain when intelligence changes and the player is under a Fortify
    -- Magicka effect.
    previousMaxMag, previousCurMag = common.recordStat(mag)
end

function this.onLoaded()
    currentInt = tes3.mobilePlayer.intelligence.currentRaw
    currentMagickaMultiplier = tes3.mobilePlayer.magickaMultiplier.current
    currentFMMag, currentTotalFMMag = common.getEffectMagNoScriptAbl(tes3.effect.fortifyMagicka)

    common.onLoaded(mag, currentTotalFMMag)

    previousMaxMag, previousCurMag = common.recordStat(mag)
end

return this