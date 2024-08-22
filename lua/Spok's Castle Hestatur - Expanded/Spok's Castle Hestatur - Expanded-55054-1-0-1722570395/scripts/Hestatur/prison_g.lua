
local prisonMarkerId = "zhac_hestatur_prisonmarker"

local prisonMarkers 
local prisonCell = "Hestatur, Prison"
local types = require("openmw.types")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local world = require("openmw.world")
local arrestMarkerId = "zhac_marker_arrestme"

local takePrisonorItems = true
local function onSave()
    return {prisonMarkers = prisonMarkers}
end
local function onLoad(data)
    if data then
        prisonMarkers = data.prisonMarkers
    end
end
local function onObjectActive(obj)
    if obj.recordId == prisonMarkerId and not prisonMarkers[obj.id] then
        obj.enabled = false
        prisonMarkers[obj.id] = {
            occupant = nil, position = obj.position, rotation = obj.rotation, 
        }
    end
end
local function buildPrisonData()
    prisonMarkers = {}
    local cell = world.getCellByName(prisonCell)
    for index, value in ipairs(cell:getAll(types.Activator)) do
        onObjectActive(value)
    end
end
local function getObjectInCell(cell, recordId)
    for index, value in ipairs(cell:getAll()) do
        if value.recordId == recordId then
            return value
        end
    end
end
local function imprisonActor(actor)
    --print("Arresting ", actor.recordId)
    if not prisonMarkers then
        buildPrisonData()
    end
    for key, value in pairs(prisonMarkers) do
        if not value.occupant then
            if takePrisonorItems then
                local cell = world.getCellByName(prisonCell)
              local cont = getObjectInCell(cell, "zhac_hest_prisonchest")
              if cont then
                prisonMarkers[key].confisicatedItems = {}
                for index, item in ipairs(types.Actor.inventory(actor):getAll()) do
                    item:moveInto(cont)
                    table.insert(prisonMarkers[key].confisicatedItems, {recordId = item.recordId, count = item.count})
                end
                --todo: add prisoner items to wear
              end
              local contOut = getObjectInCell(cell, "zhac_hest_prison_equipm")
                if contOut then
                    for index, item in ipairs(types.Actor.inventory(contOut):getAll()) do
                        item:moveInto(actor,1)
                    end
                end
            end
            prisonMarkers[key].occupant = actor.id
            actor:teleport(prisonCell, prisonMarkers[key].position, prisonMarkers[key].rotation)
            return
        end
    end
end
local function onActorActive(actor)
    if not prisonMarkers then
        return
    end
    for key, value in pairs(prisonMarkers) do
        if value.occupant == actor.id then
            actor:sendEvent("evalEquipment")
            return
        end
    end
end
local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function onActorDiedHest(actor)
    if not prisonMarkers then
        return
    end
    for key, value in pairs(prisonMarkers) do
        if value.occupant == actor.id then
          value.occupant = nil
        end
    end
end
local function sayGoodByeActor(actor)
    ----print(world.mwscript.getGlobalVariables(world.players[1]).zhac_hest_arrestme)
    if world.mwscript.getGlobalVariables(world.players[1]).zhac_hest_arrestme == 1 then
        world.mwscript.getGlobalVariables(world.players[1]).zhac_hest_arrestme = 0
        imprisonActor(actor)
    end
end
local function npcActivation(activator, actor)
    if not prisonMarkers then
        return
    end
    local guardCount = 0
    for key, value in pairs(activator.cell:getAll(types.NPC)) do
        if value.recordId == "zhac_hestatur_guard_01" then
            guardCount = guardCount + 1
        end
    end
    if guardCount > 0 then
        world.mwscript.getGlobalVariables(actor).zhac_hest_canarrest = 1
    else
        world.mwscript.getGlobalVariables(actor).zhac_hest_canarrest = 0   
    end
    for key, value in pairs(prisonMarkers) do
        --print(value.occupant, activator.id)
        if value.occupant == activator.id then
            world.mwscript.getGlobalVariables(actor).zhac_hest_talkprison = 1
            async:newUnsavableSimulationTimer(0.1, function()
                world.mwscript.getGlobalVariables(actor).zhac_hest_talkprison = 0
            end)
            return
        end
    end

end
I.Activation.addHandlerForType(types.NPC, npcActivation)

return {
    interfaceName = "zhac_prison",
    interface = {
        imprisonActor = imprisonActor,
        sayGoodByeActor = sayGoodByeActor,
        getprisonMarkers = function()
            return prisonMarkers
        end,
    },
    eventHandlers = {imprisonActor = imprisonActor, sayGoodByeActor = sayGoodByeActor,
    onActorDiedHest = onActorDiedHest,},
    engineHandlers = {
        onObjectActive = onObjectActive,
        onSave = onSave,
        onLoad = onLoad,
        onActorActive = onActorActive,
    }
}