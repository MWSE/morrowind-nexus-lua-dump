local types = require("openmw.types")

return setmetatable({}, {
    __call = function(self, pursuer, target)
        local isGameObject, isActor = pcall(types.Actor.objectIsInstance, pursuer)
        assert(isGameObject and isActor, "`Argument must be of type actor")
        -- data must be serializable
        return {
            id = pursuer.id,         -- the unique id of this data
            pursuer = pursuer,       -- the pursuer
            target = target,         -- the target being pursued
            pursuerCell = nil,       -- the cell name where pursueTarget(local) is called
            pursuerPos = nil,        -- same as above but for position
            startTime = nil,         -- the {key:realTime and key:gameTime} timestamp when pursuit started
            doorToTargetCell = nil,  -- the door that the pursuer will go to and use
            timeUntilTeleport = nil, -- the time it takes to travel to the door
            distanceToDoor = nil,    -- the distance from pursuer to doorToTargetCell
            pathUpdated = nil,       -- whether paths to doors has been updated
            pathDoor = {             -- map of doors in the cell, empty if not pathUpdated
                -- key = the door id
                -- value = {door = nil, canPath = nil, pathList = nil}
                -- door = the door object to path to
                -- canPath = if path to door is successful
                -- pathList = list of vec3 points in navmesh to the target door
            },
        }
    end
})
