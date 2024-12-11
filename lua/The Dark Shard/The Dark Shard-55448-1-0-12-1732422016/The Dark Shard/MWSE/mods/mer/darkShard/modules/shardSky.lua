--[[
Enable Nirn in sky
]]

local common = require("mer.darkShard.common")
local logger = common.createLogger("nirn")
local Nirn = require ("mer.darkShard.components.Nirn")
local Weather = require("mer.darkShard.components.Weather")
local ShardCell = require("mer.darkShard.components.ShardCell")


local function toggleNirn()
    if ShardCell.isOnShard() then
        logger:debug("Enabling Nirn")
        Nirn.enable()
        Weather.disableClouds()
    else
        Nirn.disable()
        Weather.enableClouds()
    end
end

event.register("cellChanged", toggleNirn)
event.register("loaded", toggleNirn)

event.register("loaded", function()
    timer.start({
        duration = 1,
        iterations = -1,
        callback = toggleNirn
    })
end)

local function setToMidnight()
    if not ShardCell.isOnShard() then return end
    logger:debug("Setting GameHour to 0")
    tes3.findGlobal("GameHour").value = 0
end

---@param e loadedEventData
event.register("loaded", function(e)
    ---timer to reset GameHour to 0
    timer.start{
        duration = 0.1,
        iterations = 1,
        type = timer.real,
        callback = setToMidnight
    }
end)
event.register("menuExit", setToMidnight)


--Disable levitation
---@param e cellChangedEventData | {cell: tes3cell, previousCell: tes3cell}
local function disableLevitation(e)
    if e.cell.id:lower() == ShardCell.cellId  then
        tes3.worldController.flagLevitationDisabled = true
    elseif e.previousCell and e.previousCell.id:lower() == ShardCell.cellId then
        tes3.worldController.flagLevitationDisabled = false
    end
end

event.register("cellChanged", disableLevitation)
event.register("loaded", function()
    disableLevitation{cell = tes3.player.cell}
end)
