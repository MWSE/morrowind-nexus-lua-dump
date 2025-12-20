local storage = require("openmw.storage")
local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")

require("scripts.BruteForce.utils.consts")
local L = require("scripts.BruteForce.bf_logic")
local omw_utils = require("scripts.BruteForce.utils.openmw_utils")

local sectionOnHit = storage.globalSection("SettingsBruteForce_onHit")
local sectionOnUnlock = storage.globalSection("SettingsBruteForce_onUnlock")

local function onObjectHit(o, var, res)
    if not L.registerAttack(o) then return end

    if L.attackMissed(o) or L.weaponTooWorn(o) then
        if sectionOnHit:get("damageOnH2hMisses") then
            L.damageIfH2h()
        end
        return
    end

    L.damageIfH2h()
    core.sendGlobalEvent("checkJammedLock", { o = o, sender = self })
    -- check jammed lock in global script
    -- if it's OK, it will fire a tryUnlocking event back here
end

local function lockWasntJammed(data)
    local o = data.o

    if not L.unlock(o) then
        -- lock got bent
        if sectionOnUnlock:get("enableWeaponWearAgainstBentLocks") then
            L.wearWeapon(o, self)
        end
        return
    end

    L.giveCurrWeaponXp()
    L.wearWeapon(o, self)

    if omw_utils.objectIsOwned(o) then
        L.alertNpcs()
    end

    if types.Container.objectIsInstance(o) then
        L.damageContainerEquipment(o)
    end
end

local function lockWasJammed(data)
    local o = data.o

    if sectionOnUnlock:get("enableWeaponWearAgainstBentLocks") then
        L.wearWeapon(o, self)
    end
end

omw_utils.checkDependencies(self, Dependencies)
I.impactEffects.addHitObjectHandler(onObjectHit)

return {
    eventHandlers = {
        lockWasntJammed = lockWasntJammed,
        lockWasJammed = lockWasJammed,
    },
}
