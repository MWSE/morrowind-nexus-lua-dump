local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")

local ignoreList = {}
local selfIsAGuard = false

local function stopCombat(actor)
    if selfIsAGuard then
        ai.filterPackages(function(package)
            if package.type == "Combat" then
                return package.target ~= actor
            end
            return true
        end)
    end
end

-- replace to something better in v0.49, maybe gameObject.id?
local function getID(obj)
    return tostring(obj)
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            local T = ai.getActiveTarget("Combat")
            if T and ignoreList[getID(T)] then
                stopCombat(T)
            end
        end
    },
    eventHandlers = {
        --[[ProtectiveGuards_ignoreActor_eqnx = function(data)
            local obj, ignore = data.actor, data.ignore
            if not types.Actor.objectIsInstance(obj) then
                error("ignoreActor event param actor must be of type Actor", 2)
            end
            if ignore == nil then
                ignore = true
            end
            ignoreList[getID(obj)] = ignore or nil
        end,]]
        ProtectiveGuards_alertGuard_eqnx = function(e)
            selfIsAGuard = true

            if not types.Actor.canMove(self) or not e.attacker:isValid() then
                return
            end

            ignoreList[getID(e.attacker)] = e.isImmune or nil

            if e.isImmune then
                stopCombat(e.attacker)
                return
            end
            if ignoreList[getID(e.attacker)] then
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
