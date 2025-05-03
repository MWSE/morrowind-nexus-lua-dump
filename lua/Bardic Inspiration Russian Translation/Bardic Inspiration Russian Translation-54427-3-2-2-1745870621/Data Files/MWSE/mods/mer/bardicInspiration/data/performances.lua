---@class BardicInspiration.Performance
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

---@class BardicInspiration.Performance.data
---@field day integer The day you are scheduled to perform
---@field state string The state of the performance, SCHEDULED, PLAYED, SKIP
---@field reward integer The amount of gold you are paid for the performance
---@field publicanId string The object id of the publican you are performing for
---@field publicanName string The name of the publican you are performing for

---@param performance BardicInspiration.Performance.data
function this.add(performance)
    local newData = performancesData:get()
    newData[tes3.player.cell.id] = performance
    performancesData:set(newData)
end

---@return BardicInspiration.Performance.data[]|nil
function this.getAll()
    return performancesData:get()
end

---@return BardicInspiration.Performance.data|nil
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