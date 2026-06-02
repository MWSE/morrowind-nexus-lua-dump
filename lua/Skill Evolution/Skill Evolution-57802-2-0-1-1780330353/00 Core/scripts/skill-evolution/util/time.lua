local core = require('openmw.core')
local world = require('openmw.world')

local mDef = require('scripts.skill-evolution.config.definition')

local hoursToPass = 0
local maxHoursToPass = 0
local previousPauseTags = {}
local previousTimeScale
local waitingForMidnight = false
local lastRealTime

local module = {}

module.passHours = function(hours)
    hoursToPass = hoursToPass + hours
    maxHoursToPass = math.max(maxHoursToPass, hoursToPass)
    lastRealTime = core.getRealTime()
end

-- Code taken from Time Flies mod (https://www.nexusmods.com/morrowind/mods/45727), thanks to @hyacinth!
module.onUpdate = function()
    if hoursToPass == 0 then return end

    local now = core.getRealTime()
    local dt = now - lastRealTime
    lastRealTime = now

    local globals = world.mwscript.getGlobalVariables()
    local gameHour = globals.gamehour
    if waitingForMidnight then
        if gameHour < 1 then
            -- restore previous state after midnight
            waitingForMidnight = false
            if previousTimeScale then
                world.setGameTimeScale(previousTimeScale)
                previousTimeScale = nil
            end
            for tag, _ in pairs(previousPauseTags) do
                world.pause(tag)
            end
            previousPauseTags = {}
        else
            return
        end
    end
    -- smooth log curve for duration
    -- 0.1h -> 0.12s
    -- 0.5h -> 0.18s
    --   1h -> 0.24s
    --   4h -> 0.42s
    --  10h -> 0.58s
    --  20h -> 0.71s
    --  24h -> 0.74s
    --  48h -> 0.88s
    local totalTimeForTransition = 0.1 + 0.2 * math.log(1 + maxHoursToPass)
    local speed = maxHoursToPass / totalTimeForTransition

    local step = math.min(1, dt * speed, hoursToPass, 23.999999 - gameHour)
    if step > 0.00001 then
        globals.gamehour = gameHour + step
        hoursToPass = hoursToPass - step
        if hoursToPass <= 0 then
            hoursToPass = 0
            maxHoursToPass = 0
            for _, player in pairs(world.players) do
                player:sendEvent(mDef.events.onTimePassed)
                player:sendEvent("timeHud_refreshTime")
            end
        end
    else
        -- at midnight boundary let the engine process the day transition
        previousPauseTags = world.getPausedTags()
        for tag, _ in pairs(previousPauseTags) do
            world.unpause(tag)
        end
        if world.getGameTimeScale() <= 1 then
            previousTimeScale = world.getGameTimeScale()
            world.setGameTimeScale(60)
        end
        waitingForMidnight = true
    end
end

return module