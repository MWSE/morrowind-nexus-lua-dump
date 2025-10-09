local world = require('openmw.world')
local async = require('openmw.async')
local core = require('openmw.core')
local time = require('openmw_aux.time')


local player = world.players[1]
local stopfn = nil


local alredy_cast = false
--[[
local breath = 0
local callback = async:registerTimerCallback("callBackBreathOut", function()
    breath = breath - 1
    if breath <= 0 then
        if stopfn ~= nil then 
            stopfn() 
            stopfn = nil
        end

        local player = world.players[1]
        player:sendEvent('BreathOut')
    end
end)
local callback2 = async:registerTimerCallback("callBackBreathLow", function()
    if breath == 1 then
        player:sendEvent('BreathLow')
    end
end)
]]

--[[
local function WaterLevel()
    local player = world.players[1]
    local pos = player.position
    local wl = world.getExteriorCell(pos.x, pos.y).waterLevel

    --world.getExteriorCell(world.players[1].position.x, world.players[1].position.y).waterLevel
    return wl
end
]]

local duration_left = 0
local function startBreathTimer()
    local needRemaind = duration_left >= 40
    stopfn = time.runRepeatedly(
        function()
            player:sendEvent('BreathTimer', { duration = duration_left })
            duration_left = duration_left - 1
            if needRemaind and duration_left == 10 then
                player:sendEvent('BreathLow')
            end
            if duration_left <= 0 then
                if stopfn ~= nil then 
                    stopfn() 
                    stopfn = nil
                end
                player:sendEvent('BreathOut')
            end
        end, time.second
    )

    -- 30 секунда симуляции = 1 секунда реального времени
    --[[
    breath = breath + 1
    if duration > 10 then
        async:newSimulationTimer((duration-10)*core.getSimulationTimeScale(), callback2)    
    end
    async:newSimulationTimer(duration*core.getSimulationTimeScale(), callback)
    ]]

end

local function TakeBreath(duration)

    player:sendEvent('BreathIn', { duration = duration })
    duration_left  = duration
    if stopfn == nil then  -- запускаем таймер, если он еще не запущен
        startBreathTimer()
    end

end
local function TrainedLungs(data)
    if data.duration == 0 then
        return
    end

    if data.swim and data.underwater then 
        -- мы под водой и не можем задерживать дыхание
        player:sendEvent('BreathFail')
    else 
        -- мы над водой и можем задерживать дыхание
        TakeBreath(data.duration * data.fatigue)
    end
end

local function onSave()
    return { duration_left = duration_left }
end

local function onLoad(data)
    if data.duration_left ~= nil then
        duration_left = data.duration_left
    end
    if duration_left > 0 then
        startBreathTimer()
    end
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        TrainedLungs = TrainedLungs
    }
}
