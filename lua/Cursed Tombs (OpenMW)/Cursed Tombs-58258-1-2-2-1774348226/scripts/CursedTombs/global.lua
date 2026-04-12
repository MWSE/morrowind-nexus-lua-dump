local types = require("openmw.types")
local I = require("openmw.interfaces")

require("scripts.CursedTombs.logic.container")
require("scripts.CursedTombs.logic.checks")
require("scripts.CursedTombs.logic.curse")

local triggeredContainers = {}
local activatedContainers = {}

local function onSave()
    return {
        triggeredContainers = triggeredContainers,
        activatedContainers = activatedContainers,
    }
end

local function onLoad(saveData)
    triggeredContainers = saveData.triggeredContainers
    activatedContainers = saveData.activatedContainers
end

local function flushActivatedContainers(cellId)
    for recordedCellId, _ in pairs(activatedContainers) do
        if recordedCellId ~= cellId then
            activatedContainers[recordedCellId] = nil
        end
    end
end

local function onContainerActive(obj, actor)
    if IgnoredContainer(triggeredContainers, activatedContainers, obj) then
        return
    end

    if activatedContainers[obj.cell.id] then
        activatedContainers[obj.cell.id][obj.id] = true
    else
        activatedContainers[obj.cell.id] = { [obj.id] = true }
    end
    local reventats = GetRevenants(obj)

    if not reventats
        or IsCity(obj)
        or obj.type.isLocked(obj)
        or HasKey(obj, actor)
        or GotLucky(actor)
    then
        return
    end

    flushActivatedContainers(actor.cell.id)
    triggeredContainers[obj.id] = true
    actor:sendEvent("CursedTombs_initCurse", reventats)
end

I.Activation.addHandlerForType(types.Container, onContainerActive)

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        CursedTombs_activatedContainer = function(eventData)
            onContainerActive(eventData.obj, eventData.actor)
        end,
        CursedTombs_triggerCurse = function(eventData)
            TriggerCurse(eventData.revenants, eventData.actor, eventData.spawnPos)
        end
    }
}
