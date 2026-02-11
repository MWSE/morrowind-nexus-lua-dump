local storage = require("openmw.storage")
local types = require("openmw.types")
local core = require("openmw.core")

require("scripts.BruteForce.utils.openmw_utils")
require("scripts.BruteForce.utils.detection")
require("scripts.BruteForce.logic.sounds")

local sectionOnHit = storage.globalSection("SettingsBruteForce_onHit")
local sectionOnUnlock = storage.globalSection("SettingsBruteForce_onUnlock")
local l10n = core.l10n("BruteForce")

function Unlock(o, actor, jammedLocks)
    local unlocked = false
    if math.random() > sectionOnHit:get("jamChance") then
        -- unlock lock
        o.type.unlock(o)
        unlocked = true
    else
        -- jam lock
        jammedLocks[o.id] = true
        ---@diagnostic disable-next-line: missing-parameter
        DisplayMessage(actor, l10n("lock_got_jammed"))
    end

    PlaySFX(o, actor, unlocked)

    return unlocked
end

function WearWeapon(o, actor)
    local weaponSlot = types.Actor.EQUIPMENT_SLOT.CarriedRight
    local weapon = actor.type.getEquipment(actor, weaponSlot)
    local wearMod = sectionOnUnlock:get("weaponWearModifier")

    if not weapon or wearMod == 0 then return end

    local lockLevel = types.Lockable.getLockLevel(o)
    local dmg = -math.min(
        lockLevel * wearMod,
        weapon.type.records[weapon.recordId].health
    )

    core.sendGlobalEvent("ModifyItemCondition", {
        item = weapon,
        amount = dmg,
    })
end

function GiveCurrWeaponXp(actor)
    if not sectionOnUnlock:get("enableXpReward") then return end
    actor:sendEvent("GiveCurrWeaponXp")
end

function TriggerTrap(o, actor)
    local spell = o.type.getTrapSpell(o)

    -- disarm trap
    o.type.setTrapSpell(o, nil)

    -- fire a spell on an actor
    local effectsWithParams = core.magic.spells.records[spell.id].effects
    local effects = {}
    for _, effect in ipairs(effectsWithParams) do
        table.insert(effects, effect.index)
    end
    actor.type.activeSpells(actor):add({
        id = spell.id,
        effects = effects
    })
end

function DamageContainerEquipment(o)
    if not sectionOnUnlock:get("damageContents") then return end

    local inv = o.type.inventory(o)
    -- populate container's leveled list if needed
    if not inv:isResolved() then
        inv:resolve()
    end

    for _, item in pairs(inv:getAll()) do
        if ItemCanBeDamaged(item) then
            local dmg = -math.random(item.type.records[item.recordId].health)
            core.sendGlobalEvent("ModifyItemCondition", {
                item = item,
                amount = dmg
            })
        end
    end
end
