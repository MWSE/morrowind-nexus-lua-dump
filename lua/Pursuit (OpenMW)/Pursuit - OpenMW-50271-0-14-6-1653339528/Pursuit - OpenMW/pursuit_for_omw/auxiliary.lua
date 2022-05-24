local types = require("openmw.types")
local aux_util = require("openmw_aux.util")

local this = {}

this.getBestDoor = function(actor, cell, target, position, doors)
    local bestDoor

    doors =
        aux_util.mapFilter(
        doors,
        function(door)
            return (types.Door.isTeleport(door) and types.Door.destCell(door).name == cell)
        end
    )

    if not target then
        target = {position = position}
        bestDoor =
            aux_util.findMinScore(
            doors,
            function(door)
                return (actor.position - door.position):length()
            end
        )
    else
        bestDoor =
            aux_util.findMinScore(
            doors,
            function(door)
                return ((actor.position - door.position):length() +
                    (target.position - types.Door.destPosition(door)):length())
            end
        )
    end

    return bestDoor
end

return this
