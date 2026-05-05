local async = require('openmw.async')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')

local RUN_UNLOCK_RATIO = 0.10

local runLocked = false
local controlsSettings = storage.playerSection('SettingsOMWControls')

local function getFatigueValues()
    local fatigue = types.Actor.stats.dynamic.fatigue(self)
    if fatigue == nil then
        return 0, 0
    end

    local current = tonumber(fatigue.current) or 0
    local baseValue = tonumber(fatigue.base) or 0
    local modifierValue = tonumber(fatigue.modifier) or 0
    local maxValue = math.max(0, baseValue + modifierValue)

    return current, maxValue
end

local function updateRunLock()
    local currentFatigue, maxFatigue = getFatigueValues()

    if not runLocked then
        if currentFatigue <= 0 then
            runLocked = true
            controlsSettings:set('alwaysRun', false)
        end
        return
    end

    if maxFatigue <= 0 then
        return
    end

    local unlockThreshold = maxFatigue * RUN_UNLOCK_RATIO
    if currentFatigue >= unlockThreshold then
        runLocked = false
    end
end

input.bindAction('Run', async:callback(function(_, runActionValue)
    updateRunLock()
    if runLocked then
        return false
    end
    return runActionValue
end), {})

return {
    engineHandlers = {
        onFrame = function()
            updateRunLock()
            if runLocked then
                controlsSettings:set('alwaysRun', false)
                self.controls.run = false
            end
        end,
        onLoad = function()
            runLocked = false
        end,
    },
}
