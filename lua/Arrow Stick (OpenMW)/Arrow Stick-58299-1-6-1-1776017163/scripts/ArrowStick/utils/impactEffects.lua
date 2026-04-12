local I = require("openmw.interfaces")

local IE = {}

IE.getMaterial = function(hitObj, hitWater)
    if hitWater then
        return "Water"
    elseif hitObj then
        return I.impactEffects.getMaterialByObject(hitObj)
    else
        return "Dirt"
    end
end

return IE
