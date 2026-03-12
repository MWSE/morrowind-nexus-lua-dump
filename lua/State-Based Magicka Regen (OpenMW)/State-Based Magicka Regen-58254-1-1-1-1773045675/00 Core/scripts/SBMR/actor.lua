local core = require("openmw.core")
local self = require("openmw.self")
local T = require("openmw.types")

local mStore = require("scripts.SBMR.config.store")
local mActors = require("scripts.SBMR.util.actors")
local mH = require("scripts.SBMR.util.helpers")
local log = require("scripts.SBMR.util.log")

local lastUpdateTime = 0
local prevGameTime = core.getGameTime()
local prevMagicka = mActors.magicka.current
local paused = false
local mainStatPercentSetting = self.type == T.Player
        and mStore.settings.playerMainStatRegenPerMinPercent
        or mStore.settings.actorsMainStatRegenPerMinPercent

local function getRegen(currMagicka, time)
    local regen = 0
    local factor = mActors.getRegenFactor()
    if factor ~= 0 then
        regen = factor * mActors.getBaseRegen(time, mainStatPercentSetting.value)
    end
    local extChange = currMagicka - prevMagicka
    if not mH.areFloatEqual(extChange, 0) then
        log(string.format("External magicka change of %.3f", extChange))
    end
    if regen == 0 then
        return 0
    end
    if extChange > 0 then
        regen = math.max(0, regen - extChange)
    end
    -- cap the regen after resting, waiting, traveling...
    return math.min(regen, math.max(0, mActors.magicka.base - currMagicka))
end

local function regenMagicka(time)
    local currMagicka = mActors.magicka.current
    local regen = 0
    if time > 0 and mStore.settings.enabled.value then
        regen = getRegen(currMagicka, time)
        if regen > 0 then
            mActors.magicka.current = currMagicka + regen
            log(string.format("Regenerated %.3f magicka", regen))
        end
    end
    prevMagicka = currMagicka + regen
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
    if not wasPaused and lastUpdateTime < 1 then return end
    lastUpdateTime = 0

    local gameTime = core.getGameTime()
    local time = (gameTime - prevGameTime) / core.getGameTimeScale()
    prevGameTime = gameTime
    regenMagicka(time)
end

return {
    engineHandlers = {
        onInit = onInit,
        onUpdate = onUpdate,
    },
}
