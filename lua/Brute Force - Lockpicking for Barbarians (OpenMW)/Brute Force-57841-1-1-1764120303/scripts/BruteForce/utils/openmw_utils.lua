local types = require("openmw.types")
local core = require("openmw.core")

require("scripts.BruteForce.utils.consts")

local utils = {}

function utils.getEquippedWeaponSkillId(actor)
    local weapon = actor.type.getEquipment(actor, actor.type.EQUIPMENT_SLOT.CarriedRight)
    if weapon then
        local weaponType = weapon.type.records[weapon.recordId].type
        return WeaponTypeToSkillId[weaponType]
    else
        return "handtohand"
    end
end

function utils.getEquippedWeaponSkill(actor)
    local weapon = actor.type.getEquipment(actor, actor.type.EQUIPMENT_SLOT.CarriedRight)
    if weapon then
        local weaponType = weapon.type.records[weapon.recordId].type
        return WeaponTypeToSkill[weaponType](actor)
    else
        return actor.type.stats.skills.handtohand(actor)
    end
end

function utils.calcHitChance(actor)
    local weaponSkill = utils.getEquippedWeaponSkill(actor).modified
    local agility = actor.type.stats.attributes.agility(actor).modified
    local luck = actor.type.stats.attributes.luck(actor).modified

    local fatigue = actor.type.stats.dynamic.fatigue(actor)
    local currFatigue = fatigue.current
    local baseFatigue = fatigue.base

    local activeEffects = actor.type.activeEffects(actor)
    local fortAttack = activeEffects:getEffect("fortifyattack").magnitude
    local blind = activeEffects:getEffect("blind").magnitude

    return (
        (weaponSkill + agility / 5 + luck / 10)
        * (.75 + (.5 * (currFatigue / baseFatigue)))
        + fortAttack - blind
    ) / 100
end

-- dependencies: table where key = file name, value = boolean indicating whether required interface is missing
-- e.g. { ["Impact Effects.omwscripts"] = I.impactEffects == nil }
-- if mod has no interfaces, set it's value to false
-- e.g. { ["Some Mod.omwscripts"] = false }
function utils.checkDependencies(player, dependencies)
    for fileName, interfaceMissing in pairs(dependencies) do
        local filePresent = core.contentFiles.has(string.lower(fileName))
        if not filePresent or interfaceMissing then
            player:sendEvent('ShowMessage', {
                message = "[Brute Force] ERROR: Dependency \""
                    .. fileName .. "\" is either missing or loaded after the Brute Force."
            })
        end
    end
end

function utils.itemCanBeDamaged(item)
    if not DamageableItemTypes[item.type] then return false end

    if item.type == types.Weapon then
        local wType = item.type.records[item.recordId].type
        if NonDamageableWeaponTypes[wType] then return false end
    end

    return true
end

return utils
