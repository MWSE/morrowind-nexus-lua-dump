local types = require("openmw.types")

local dummies = require("scripts.PracticeDummies.dummies")

local function rangedHandler(data)
    if not dummies.isDummy(data.hitObj)
        or not types.Player.objectIsInstance(data.actor)
    then
        return
    end

    local weaponType = data.weapon.type.records[data.weapon.recordId].type
    data.actor:sendEvent("PracticeDummies_rangedAttack", weaponType)
end

return {
    eventHandlers = {
        ArrowStick_PlaceNewArrow = rangedHandler,
    }
}
