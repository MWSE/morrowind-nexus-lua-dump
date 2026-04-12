local core = require("openmw.core")
local self = require("openmw.self")
local T = require("openmw.types")

local mDef = require("scripts.SBMR.config.definition")
local mStore = require("scripts.SBMR.config.store")
local mActors = require("scripts.SBMR.util.actors")
local mH = require("scripts.SBMR.util.helpers")
local log = require("scripts.SBMR.util.log")

local updateFrequency = 0.5
local lastUpdateTime = 0
local prevGameTime = core.getGameTime()
local prevMagicka = mActors.magicka.current
local paused = false
local mainStatPercentSetting = self.type == T.Player
        and mStore.settings.playerMainStatRegenPerMinPercent
        or mStore.settings.actorsMainStatRegenPerMinPercent

local function getRegen(gameTimePassed)
    local timescale
    local factor = mActors.getRegenFactor()
    local extChange = mH.round(mActors.magicka.current - prevMagicka, 5)
    if gameTimePassed > 120 * updateFrequency then
        timescale = mStore.settings.timescaleForLongPeriodsOfTimePassed.value
        log(string.format("A long time (%d sec) as passed, will use a timescale of %d", gameTimePassed, timescale))
        if extChange > 0 then
            log(string.format("Has rested in a bed, cancelling the %.3f vanilla restored magicka", extChange))
            mActors.magicka.current = prevMagicka
            factor = factor * mStore.settings.restInBedRegenPercent.value / 100
        end
    elseif extChange ~= 0 then
        log(string.format("External magicka change of %.3f", extChange))
    end
    timescale = timescale or core.getGameTimeScale()
    local baseRegen = mActors.getBaseRegen(mainStatPercentSetting.value)
    local timePassed = gameTimePassed / timescale
    local regen = factor * baseRegen * timePassed / 60
    if self.type == T.Player then
        self:sendEvent(mDef.events.setCurrPlayerRegen, factor * baseRegen)
    end
    -- cap the regen after resting, waiting, traveling...
    return math.min(regen, math.max(0, mActors.magicka.base - mActors.magicka.current)), factor, timePassed
end

local function regenMagicka(gameTimePassed)
    local regen, factor, timePassed = 0, 0, 0
    if gameTimePassed > 0 and mStore.settings.enabled.value then
        regen, factor, timePassed = getRegen(gameTimePassed)
        log(string.format("Regenerated %.3f magicka over %.3f sec (factor = %.3f)", regen, timePassed, factor))
        if regen > 0 then
            mActors.magicka.current = mActors.magicka.current + regen
        end
    end
    prevMagicka = mActors.magicka.current
end

local function onInit(data)
    if data and data.passedTime then
        regenMagicka(data.passedTime)
    end
end

local function onUpdate(dt)
    if dt == 0 then
        paused = true
        return
    end
    local wasPaused = paused
    paused = false

    lastUpdateTime = lastUpdateTime + dt
    -- wasPaused: Instant magicka update after resting, waiting, traveling...
    if not wasPaused and lastUpdateTime < updateFrequency then return end
    lastUpdateTime = 0

    local gameTime = core.getGameTime()
    local gameTimePassed = (gameTime - prevGameTime)
    prevGameTime = gameTime
    regenMagicka(gameTimePassed)
end

return {
    engineHandlers = {
        onInit = onInit,
        onUpdate = onUpdate,
    },
}
