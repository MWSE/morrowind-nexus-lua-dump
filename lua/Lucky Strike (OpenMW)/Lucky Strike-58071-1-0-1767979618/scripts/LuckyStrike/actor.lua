local storage = require('openmw.storage')
local core = require("openmw.core")
local self = require("openmw.self")
local I = require("openmw.interfaces")

local settings = storage.globalSection('SettingsLuckyStrike_settings')

local function tryCrit(attack)
    if not attack.successful then return end

    local luck = attack.attacker.type.stats.attributes.luck(attack.attacker)
    if not (math.random() < (luck.modified / 100) ^ 3 / 2) then return end

    local weaponSpeed = 1
    local weapon = attack.weapon
    if weapon and not attack.ammo then
        weaponSpeed = weapon.type.records[weapon.recordId].speed
    end

    local dmg = attack.damage
    if dmg.health ~= nil then
        attack.damage.health = dmg.health * weaponSpeed * settings:get("baseHpCritMult")
    end
    if dmg.fatigue ~= nil then
        attack.damage.fatigue = dmg.fatigue * weaponSpeed * settings:get("baseFatCritMult")
    end
    if dmg.magicka ~= nil then
        attack.damage.magicka = dmg.magicka * weaponSpeed * settings:get("baseMagCritMult")
    end
    
    core.sound.playSound3d("critical damage", self)
end

I.Combat.addOnHitHandler(tryCrit)
