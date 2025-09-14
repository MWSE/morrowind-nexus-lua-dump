local storage = require("openmw.storage")

require("scripts.DeadMerTellNoTales.blacklists")

DeadActors = {}
local sectionDebug = storage.globalSection("DeadMerTellNoTales_debug")

local function onSave()
    return DeadActors
end

local function onLoad(savedData, initData)
    if savedData ~= nil then
        DeadActors = savedData
    end
end

local function disown(objects)
    for _, object in ipairs(objects) do
        -- HOW THE FUCK
        if object.owner.recordId == nil then return end

        if sectionDebug:get("debugEnabled") then
            print(
                tostring(object.owner.recordId) ..
                " lost ownership of " ..
                object.recordId)
        end

        object.owner.recordId = nil
    end
end

local function checkActorStatus(object)
    -- how tf
    if object.owner.recordId == nil then return end
    
    if not DeadActors[object.owner.recordId] then return end
    
    if ActorBlacklist[string.lower(object.owner.recordId)]
       or CellBlacklist[string.lower(object.cell.name)] then
        return

    elseif object.cell.isExterior then
        local cellCoords = tostring(object.cell.gridX) .. "," .. tostring(object.cell.gridY)
        if CellBlacklist[cellCoords] then
            return
        end
    end

    disown({ object })
end

local function onObjectActive(object)
    if object.owner.recordId ~= nil then
        checkActorStatus(object)
    end
end

local function recordDead(recordId)
    DeadActors[recordId] = true
end

return {
    engineHandlers = {
        onObjectActive = onObjectActive,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        disown = disown,
        recordDead = recordDead,
    }
}
