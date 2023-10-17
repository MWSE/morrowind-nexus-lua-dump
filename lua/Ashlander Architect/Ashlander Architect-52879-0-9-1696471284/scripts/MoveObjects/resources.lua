local data = require("scripts.MoveObjects.utility.record_data")
local types = require("openmw.types")
local ui = require("openmw.ui")
local self = require("openmw.self")
local core = require("openmw.core")
local knownResources = {}
local time = require('openmw_aux.time')
local function attemptHarvest(itemID, object, objectName)
    local record = data[itemID:lower()]
    if not knownResources[object.id] then
        knownResources[object.id] = { remainingSwings = math.random(1, 6) }
    end
    if knownResources[object.id].remainingSwings > 0 then
        knownResources[object.id].remainingSwings = knownResources[object.id].remainingSwings - 1
        local itemsGiven = math.random(1, 5)
        if knownResources[object.id].remainingSwings == 0 then
            knownResources[object.id].nextHarvest = core.getGameTime() + (time.day * math.random(1, 5))
            print("nh", knownResources[object.id].nextHarvest)
            ui.showMessage(string.format("You swing at the %s, cutting down %i %ss from it, exhausting it.",
            objectName, itemsGiven, record.name))
        else

        ui.showMessage(string.format("You swing at the %s, cutting down %i %ss from it.",
        objectName, itemsGiven, record.name))
        end
        core.sendGlobalEvent("ZackUtilsAddItem_AA",
            { actor = self, itemId = itemID, count = itemsGiven, equip = false })
    else
        if core.getGameTime() > knownResources[object.id].nextHarvest then
            knownResources[object.id] = { remainingSwings = math.random(1, 6) }
        else
            ui.showMessage("You are unable to harvest any more from this resource")
        end
    end
end
local function attemptTreeHarvest(object)
    attemptHarvest("mc_log_pine", object, "Tree")
end
local function attemptRockHarvest(object)
    attemptHarvest("mc_silver_ore", object, "Rock")
end
local function onSave()
    return { knownResources = knownResources }
end
local function onLoad(data)
    if not data then return end
    knownResources = data.knownResources
end
return {
    interfaceName = "MoveObjects_Resources",
    interface = {
        version = 1,
        attemptRockHarvest = attemptRockHarvest,
        attemptTreeHarvest = attemptTreeHarvest
    },
    eventHandlers = {
    },
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    }
}
