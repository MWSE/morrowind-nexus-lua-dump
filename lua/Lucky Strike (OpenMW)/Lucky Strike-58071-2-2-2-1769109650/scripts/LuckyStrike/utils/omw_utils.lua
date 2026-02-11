local storage = require('openmw.storage')
local types = require("openmw.types")

local settingsDebug = storage.globalSection('SettingsLuckyStrike_debug')

function GetWeaponType(attack)
    if not attack.weapon then return "unarmed" end

    -- for throwables
    if attack.weapon.id == "@0x0" then
        return types.Weapon.records[attack.ammo].type
    end

    return types.Weapon.records[attack.weapon.recordId].type
end

function GetWeaponSkill(attack)
    if attack.attacker.type == types.Creature then
        return attack.attacker.type.records[attack.attacker.recordId].combatSkill
    end

    local weaponType = GetWeaponType(attack)
    local weaponSkill = WeaponTypes[weaponType](attack.attacker)
    return weaponSkill.modified
end

function IsBackHit(victim, attacker, fov)
    local attackerYaw = attacker.rotation:getYaw()
    local victimYaw = victim.rotation:getYaw()
    local diff = math.abs(victimYaw - attackerYaw)
    local npcFov = math.pi * math.abs(fov - 360) / 360
    return diff > npcFov
end

function Log(message)
    if settingsDebug:get("log") then
        print(message)
    end
end
