local guardMarkerId = "zhac_hestatur_guardmarker"
local world = require("openmw.world")
local types = require("openmw.types")
local guardMarkers = {}
local guardRevision = 1
local barrierBroken = false
local guardsActive = false
local guardId
local function getGuardId()
    return guardId or "zhac_hestatur_guard_01"
end
local function setGuardId(id)
    guardId = id
    guardRevision = guardRevision + 1
end --golden saint_summon
local function getGuardItems()
    local items = {
        "torch_infinite_time",
        "imperial cuirass_armor",
        "imperial_greaves",
        "imperial boots",
        "imperial left gauntlet",
        "imperial right gauntlet",
        "imperial left pauldron",
        "imperial right pauldron",
        "imperial belt",
        "imperial shield",
        "imperial skirt_clothing",
        "imperial broadsword"
    }
    return items
end
local function addGuardItems(guard)
    local items = getGuardItems()
    for index, value in ipairs(items) do
        local item = world.createObject(value)
        item:moveInto(guard)
    end
    guard:sendEvent("equipItems", items)
end
local function getObjInCell(cell, id)
    for index, value in ipairs(cell:getAll()) do
        if value.recordId == id then
            return value
        end
    end
end
local function getActorInCell(cell, id)
    for index, value in ipairs(cell:getAll()) do
        if value.id == id then
            return value
        end
    end
end
local function onObjectActive(obj)
    if world.mwscript.getGlobalVariables(world.players[1]).zhac_hest_factionActive == 0 then
            return
    end
    if obj.recordId == guardMarkerId then
        --print("xguard not ready to spawn " .. guardRevision)
    end
    if obj.recordId == guardMarkerId and not guardMarkers[obj.id] then
        obj.enabled = false
        local newGuard = world.createObject(getGuardId())
        addGuardItems(newGuard)
        newGuard:teleport(obj.cell, obj.position, obj.rotation)
        guardMarkers[obj.id] = {}
        guardMarkers[obj.id].id = newGuard.id
        guardMarkers[obj.id].revision = guardRevision
    elseif obj.recordId == guardMarkerId and guardMarkers[obj.id] ~= nil and guardMarkers[obj.id].revision ~= guardRevision then
        --print(guardMarkers[obj.id].revision)
        local obj = getActorInCell(obj.cell, guardMarkers[obj.id].id)
        if obj then
            obj:remove()
        end
        local newGuard = world.createObject(getGuardId())
        addGuardItems(newGuard)
        newGuard:teleport(obj.cell, obj.position, obj.rotation)
        guardMarkers[obj.id] = {}
        guardMarkers[obj.id].id = newGuard.id
        guardMarkers[obj.id].revision = guardRevision
    elseif obj.recordId == guardMarkerId and guardMarkers[obj.id] ~= nil and guardMarkers[obj.id].revision == guardRevision then
        --print("xguard not ready to spawn " .. guardRevision)
    elseif obj.recordId == guardMarkerId then
        --print("guard not ready to spawn " .. guardRevision)
    end
end
local function onActorActive(actor)
    for index, obj in ipairs(actor.cell:getAll(types.Activator)) do
        if obj.recordId == guardMarkerId  then
            onObjectActive(obj)
        end
    end
end

local function onSave()
    return { guardMarkers = guardMarkers, guardRevision = guardRevision, barrierBroken = barrierBroken, guardsActive =
    guardsActive }
end
local function onLoad(data)
    if data then
        guardMarkers = data.guardMarkers
        barrierBroken = data.barrierBroken
        guardRevision = data.guardRevision
        guardsActive = data.guardsActive or false
    end
end
return {
    eventHandlers = { setGuardId = setGuardId, onCellChange_Hest = onCellChange_Hest },
    engineHandlers = {
        onObjectActive = onObjectActive,
        onSave = onSave,
        onLoad = onLoad,
        onActorActive = onActorActive,
    }
}
