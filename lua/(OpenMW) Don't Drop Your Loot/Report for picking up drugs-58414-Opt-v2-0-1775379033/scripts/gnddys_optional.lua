local types = require('openmw.types')
local Activation = require('openmw.interfaces').Activation

local CONTRABAND = { ["potion_skooma_01"] = true, ["ingred_moon_sugar_01"] = true }
local CONTRABAND_OWNER = "ken"

Activation.addHandlerForType(types.Potion, function(obj, actor)
    if not CONTRABAND[obj.recordId] then return true end
    if obj.owner and obj.owner.recordId then return true end
    obj.owner.recordId = CONTRABAND_OWNER
    return true
end)

Activation.addHandlerForType(types.Ingredient, function(obj, actor)
    if not CONTRABAND[obj.recordId] then return true end
    if obj.owner and obj.owner.recordId then return true end
    obj.owner.recordId = CONTRABAND_OWNER
    return true
end)