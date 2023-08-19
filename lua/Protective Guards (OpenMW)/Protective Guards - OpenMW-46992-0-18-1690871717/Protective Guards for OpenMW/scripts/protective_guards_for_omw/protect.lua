local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local ignoreList = {}
local function stopCombat(actor)
    ai.filterPackages(function(package)
        if package.type == "Combat" then
            return package.target ~= actor
        end
        return true
    end)
end

-- replace with gameobject.id in v0.49
local function getID(obj)
    return tostring(obj):match("object%d+_.+") or 0
end

return {
    interfaceName = "PROTECTIVE_GUARDS_PROTECTOR",
    interface = {
        version = require("scripts.protective_guards_for_omw.modInfo").MOD_VERSION,
        ignoreList = function(obj, ignore)
            if type(obj) ~= "userdata" or not obj.type then
                error("First argument for ignoreList must be a GameObject", 2)
            end
            if obj.type.baseType == types.Actor or obj.type.baseType == types.NPC then
                if ignore == nil then
                    return ignoreList[getID(obj)]
                end
                ignoreList[getID(obj)] = ignore or nil
                return ignoreList[getID(obj)]
            else
                error("Object to ignore must be an actor", 2)
            end
        end
    },
    engineHandlers = {
        onUpdate = function(dt)
            local T = ai.getActiveTarget("Combat")
            if T and ignoreList[getID(T)] then
                stopCombat(T)
            end
        end
    },
    eventHandlers = {
        ProtectiveGuards_alertGuard_eqnx = function(e)
            if not types.Actor.canMove(self) or not e.attacker:isValid() then
                return
            end
            ignoreList[getID(e.attacker)] = e.isImmune or nil
            if e.isImmune then
                stopCombat(e.attacker)
                return
            end
            ai.startPackage({
                type = "Combat",
                target = e.attacker,
                cancelOther = false
            })
        end
    }
}
