local core = require("openmw.core")
local storage = require("openmw.storage")
local types = require("openmw.types")

require("scripts.BruteForce.logic.onUnlock")

local sectionOnUnlock = storage.globalSection("SettingsBruteForce_onUnlock")
local l10n = core.l10n("BruteForce")

function LockWasntJammed(o, player, jammedLocks)
    if not Unlock(o, player, jammedLocks) then
        -- lock got bent
        if sectionOnUnlock:get("enableWeaponWearAgainstBentLocks") then
            WearWeapon(o, player)
        end
        return
    end

    GiveCurrWeaponXp(player)
    WearWeapon(o, player)

    if o.type.getTrapSpell(o) and sectionOnUnlock:get("triggerTraps") then
        TriggerTrap(o, player)
    end

    if ObjectIsOwned(o, player) then
        player:sendEvent("AggroGuards")
    end

    if types.Container.objectIsInstance(o) then
        DamageContainerEquipment(o)
    end
end

function LockWasJammed(o, player)
    ---@diagnostic disable-next-line: missing-parameter
    DisplayMessage(player, l10n("lock_was_jammed"))

    if sectionOnUnlock:get("enableWeaponWearAgainstBentLocks") then
        WearWeapon(o, player)
    end

    if o.type.getTrapSpell(o) and sectionOnUnlock:get("triggerTraps") then
        TriggerTrap(o, player)
    end
end
