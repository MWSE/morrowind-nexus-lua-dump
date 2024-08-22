local list = require("scripts.Hestatur.cellList")
local core = require("openmw.core")
local function runInit()
    for index, value in ipairs(list) do
       -- core.sendGlobalEvent("setLayerInCellToDefault",value)
    end
    for index, value in ipairs(list) do
       -- core.sendGlobalEvent("turnCellLightsOff_Hest",value)
    end
end

local function onInit()
    runInit()
end


return {
    eventHandlers = {
        runInit = runInit
    },
    engineHandlers = {
        onInit = onInit,
    }
}