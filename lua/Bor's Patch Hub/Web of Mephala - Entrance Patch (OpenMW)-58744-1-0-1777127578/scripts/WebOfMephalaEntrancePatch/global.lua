local I = require("openmw.interfaces")
local types = require("openmw.types")
local util = require("openmw.util")

I.Activation.addHandlerForType(
    types.Door,
    function(obj, actor)
        if obj.cell.id ~= "vivec, arena storage"
            or not obj.type.isTeleport(obj)
            or obj.type.destCell(obj).id ~= "vivec, arena hidden area"
            or obj.type.isLocked(obj)
            or obj.type.getTrapSpell(obj)
            or not types.Player.objectIsInstance(actor)
        then
            return true
        end

        ---@type GameObject
        local doorBack
        for _, door in ipairs(obj.type.destCell(obj):getAll(types.Door)) do
            if door.type.destCell(door).id == "vivec, arena storage" then
                doorBack = door
                break
            end
        end

        actor:teleport(
            obj.type.destCell(obj),
            doorBack.position + util.vector3(0, 0, -200),
            {
                onGround = true,
                rotation = util.transform.rotateX(0)
                    * util.transform.rotateY(0)
                    * util.transform.rotateZ(0),
            }
        )
        return false
    end
)
