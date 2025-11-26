local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")

require("scripts.BruteForce.utils.consts")
local L = require("scripts.BruteForce.bf_logic")
local omw_utils = require("scripts.BruteForce.utils.openmw_utils")

local function onObjectHit(o, var, res)
    if not L.registerAttack(o) then return end

    L.damageIfH2h()

    if L.attackMissed(o) then return end

    core.sendGlobalEvent("checkJammedLock", { o = o, sender = self })
    -- check jammed lock in global script
    -- if it's OK, it will fire a tryUnlocking event back here
end

local function tryUnlocking(data)
    local o = data.o

    if not L.unlock(o) then return end

    L.giveCurrWeaponXp()

    if L.objectIsOwned(o) then
        L.alertNpcs()
    end

    if types.Container.objectIsInstance(o) then
        L.damageContainerEquipment(o)
    end
end

omw_utils.checkDependencies(self, Dependencies)
I.impactEffects.addHitObjectHandler(onObjectHit)

return {
    eventHandlers = {
        tryUnlocking = tryUnlocking,
    },
}
