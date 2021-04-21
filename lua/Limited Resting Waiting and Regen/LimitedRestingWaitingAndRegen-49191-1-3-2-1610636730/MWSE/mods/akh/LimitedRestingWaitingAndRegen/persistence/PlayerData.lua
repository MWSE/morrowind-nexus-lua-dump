local modInfo = require('akh.LimitedRestingWaitingAndRegen.ModInfo')

local data = {}
event.register("loaded", function()
    tes3.player.data[modInfo.modName] = tes3.player.data[modInfo.modName] or {}
    data = tes3.player.data[modInfo.modName]
end)

local playerData = {}

function playerData.setLastRestedTimestamp(timestamp)
    if timestamp == nil or timestamp < -1 then
        data.lastRestedTimestamp = -1
    else
        data.lastRestedTimestamp = timestamp
    end
end

function playerData.getLastRestedTimestamp()
    return data.lastRestedTimestamp or -1
end

function playerData.setLastWaitedTimestamp(timestamp)
    if timestamp == nil or timestamp < -1 then
        data.lastWaitedTimestamp = -1
    else
        data.lastWaitedTimestamp = timestamp
    end
end

function playerData.getLastWaitedTimestamp()
    return data.lastWaitedTimestamp or -1
end

return playerData