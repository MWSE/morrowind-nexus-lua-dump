local types = require('openmw.types')

local M = {}

local function moveItem(item, destInventory)
    if not item or not item:isValid() then
        return false
    end
    local ok = pcall(function()
        item:moveInto(destInventory)
    end)
    return ok
end

-- Move loose inventory and equipped gear from an NPC to a creature (best-effort).
function M.transferActorLoot(fromActor, toActor)
    if not fromActor or not fromActor:isValid() or not toActor or not toActor:isValid() then
        return false
    end

    local destInventory = types.Actor.inventory(toActor)
    local srcInventory = types.Actor.inventory(fromActor)

    -- Equipped items cannot always be moveInto'd directly; unequip to inventory first.
    pcall(function()
        types.Actor.setEquipment(fromActor, {})
    end)

    if not srcInventory:isResolved() then
        pcall(function()
            srcInventory:resolve()
        end)
    end

    for _, item in ipairs(srcInventory:getAll()) do
        moveItem(item, destInventory)
    end

    for _, item in pairs(types.Actor.getEquipment(fromActor)) do
        moveItem(item, destInventory)
    end

    return true
end

return M
