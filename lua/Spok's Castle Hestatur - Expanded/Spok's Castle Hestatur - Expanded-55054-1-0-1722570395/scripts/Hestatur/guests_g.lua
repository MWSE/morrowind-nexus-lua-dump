
local guestMarkerId = "zhac_hestatur_guestmarker"
local world = require("openmw.world")
local guestMarkers = {}
local guestCell = "Hestatur, Prison"
local function onObjectActive(obj)
    if obj.recordId == guestMarkerId and not guestMarkers[obj.id] then
        obj.enabled = false
        guestMarkers[obj.id] = {
            occupant = nil, position = obj.position, rotation = obj.rotation, 
        }
    end
end

local function onSave()
    return {guestMarkers = guestMarkers}
end
local function onLoad(data)
    if data then
        guestMarkers = data.guestMarkers
    end
end
local function addGuestActor(actor)
    for key, value in pairs(guestMarkers) do
        --print(key)
        if not value.occupant then
            guestMarkers[key].occupant = actor.id
            guestMarkers[key].originalPos = actor.position
            guestMarkers[key].originalCell = actor.cell.id
            guestMarkers[key].originalRot = actor.rotation

            actor:teleport(guestCell, guestMarkers[key].position, guestMarkers[key].rotation)
            return
        end
    end
end
local function returnGuestActor(actor)
    for key, value in pairs(guestMarkers) do
   
        if  value.occupant == actor.id then
            guestMarkers[key].occupant = actor.id
            guestMarkers[key].originalPos = actor.position
            guestMarkers[key].originalCell = actor.cell.id
            guestMarkers[key].originalRot = actor.rotation
            
            actor:teleport(world.getCellById(guestMarkers[key].originalCell),  guestMarkers[key].originalPos,  guestMarkers[key].originalRot)
            guestMarkers[key] = nil
            return
        end
    end
end
return {
    eventHandlers = {addGuestActor = addGuestActor, returnGuestActor = returnGuestActor},
    engineHandlers = {
        onObjectActive = onObjectActive,
        onSave = onSave,
        onLoad = onLoad,
    }
}