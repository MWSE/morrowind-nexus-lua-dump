local this = {}
local performancesData
--[[
    performances: {
        [cellId]: {
            day: which day you are scheduled to perform
            state: SCHEDULED, PLAYED, SKIP
        }
    }
]]
this.STATE = {
    SCHEDULED = "SCHEDULED",
    PLAYED = "PLAYED",
    SKIP = "SKIP"
}

function this.add(performance)
    local newData = performancesData:get()
    newData[tes3.player.cell.id] = performance
    performancesData:set(newData)
end

function this.getAll()
    return performancesData:get()
end 

function this.getCurrent()
    return performancesData:get()[tes3.player.cell.id]
end

function this.clearCurrent()
    performancesData:get()[tes3.player.cell.id] = nil
end

local function onLoad()
    performancesData = mwse.mcm.createPlayerData{
        id = "performances",
        path = "bardicInspiration",
        defaultSetting = {}
    }
    performancesData:get()
end
event.register("BardicInspiration:DataLoaded", onLoad)

return this