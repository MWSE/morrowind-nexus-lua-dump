local data = require("scripts.MoveObjects.utility.record_data")
local types = require("openmw.types")
local ui = require("openmw.ui")
local self = require("openmw.self")
local core = require("openmw.core")
local storage = require("openmw.storage")
local knownResources = {}
local time = require('openmw_aux.time')
local ambient = require('openmw.ambient')
local config = require("scripts.MoveObjects.config")
local RecordStorage = storage.globalSection("RecordStorage")
local function attemptHarvest(itemID, object, objectName, suceedSound, failSound)
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

        if suceedSound and not objectName == "Tree" then
            ambient.playSound(suceedSound)
            print(objectName)
        else
            print(objectName)
            ambient.playSoundFile("sounds/ashlanderarchitect/chopshort.wav")
            
        end
        core.sendGlobalEvent("ZackUtilsAddItem_AA",
            { actor = self, itemId = itemID, count = itemsGiven, equip = false })
    else
        if core.getGameTime() > knownResources[object.id].nextHarvest then
            knownResources[object.id] = { remainingSwings = math.random(1, 6) }
        else
            if failSound then
                ambient.playSound(failSound)
            end
            ui.showMessage("You are unable to harvest any more from this resource")
        end
    end
end
local function matchCondition(conditionName, recordId)
    if conditionName == "Tree" then
        if (string.sub(recordId, 1, 10) == "flora_tree") then
            return true
        elseif string.find(recordId,"flora_tree") then
                return true
        elseif recordId == "zhac_aa_treedone_gl" then
            return true
        end
    end
    if conditionName == "Rock" then
        if (string.sub(recordId, 1, 12) == "terrain_rock") then
            return true
        elseif recordId == "zhac_aa_treedone_gl" then
            return true
        elseif string.find(recordId,"t_menhir") then
            return true
        elseif string.find(recordId,"t_rock") then
            return true
        end
    end
    return false
end
local function attemptTreeHarvest(object)
    attemptHarvest("mc_log_pine", object, "Tree","sounds/ashlanderarchitect/chopshort.wav")
end
local function attemptRockHarvest(object)
    attemptHarvest("mc_silver_ore", object, "Rock", "light armor hit", "repair fail")
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
        attemptTreeHarvest = attemptTreeHarvest,
        matchCondition = matchCondition,
    },
    eventHandlers = {
    },
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    }
}
