local actorSwap = {}

local types = require("openmw.types")
function actorSwap.doActorSwap(actor1, actor2, doTP)
    local actor1Inv = {}
    local actor2Inv = {}
    local actor1Equip = types.Actor.getEquipment(actor1)
    local actor2Equip = types.Actor.getEquipment(actor2)

    for index, item in ipairs(types.Actor.inventory(actor1):getAll()) do
        table.insert(actor1Inv, item)
    end
    for index, item in ipairs(types.Actor.inventory(actor2):getAll()) do
        table.insert(actor2Inv, item)
    end
    for index, item in ipairs(actor1Inv) do
        item:moveInto(actor2)
    end
    for index, item in ipairs(actor2Inv) do
        item:moveInto(actor1)
    end
    actor1:sendEvent("CA_setEquipment", actor2Equip)
    actor2:sendEvent("CA_setEquipment", actor1Equip)
    if doTP ~= false then
        local actor1pos = actor1.position
        local actor1cell = actor1.cell
        local actor1rot = actor1.rotation
        local actor2pos = actor2.position
        local actor2cell = actor2.cell
        local actor2rot = actor2.rotation
        if actor2cell ~= nil then
            actor1:teleport(actor2cell, actor2pos, actor2rot)
        end
        actor2:teleport(actor1cell, actor1pos, actor1rot)
    end
end

return actorSwap
