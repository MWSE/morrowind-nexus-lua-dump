local types = require("openmw.types")


local this = {}


local actorTypes = {
    [types.NPC] = true,
    [types.Creature] = true,
}


---@return boolean
function this.isActorType(type)
    return actorTypes[type] and true or false
end


return this