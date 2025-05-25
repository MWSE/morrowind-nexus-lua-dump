-- Core logic for replacing static keg models with usable ones,
-- OpenMW modules
local world     = require("openmw.world")
local types     = require("openmw.types")

-- Known keg model IDs (to be replaced on activation)
local kegStaticIds = {
    ["furn_com_kegstand"]       = true,
    ["furn_de_kegstand"]        = true,
}
-- Determine if object should be replaced with a usable keg
local shouldReplace
    shouldReplace = function(obj)
        return obj.type == types.Static and kegStaticIds[obj.recordId:lower()]
    end

-- Called when keg object is added to world; replaces it with usable keg
local function onObjectActive(obj)
    if shouldReplace(obj) then

        local record = obj.type == types.Static and types.Static.record(obj.recordId)
                    or obj.type == types.Activator and types.Activator.record(obj.recordId)

        local newObj = world.createObject("detd_Furn_Com_Kegstand", 1)

        newObj.enabled = obj.enabled
        newObj:setScale(obj.scale)
        newObj:teleport(obj.cell, obj.position, obj.rotation)
        obj:remove()
    end
end


-- Main API export
return {
    engineHandlers = {
        onObjectActive = onObjectActive
    }
}

