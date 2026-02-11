local storage = require('openmw.storage')

require("scripts.LuckyStrike.utils.omw_utils")

local settingsDamage = storage.globalSection('SettingsLuckyStrike_damage')

local function getDamageMult(attack)
    local weaponSkill = GetWeaponSkill(attack)
    local skillMult = settingsDamage:get("weaponSkillMult")

    local weaponSpeed = 1
    local weapon = attack.weapon
    if weapon and not attack.ammo then
        weaponSpeed = weapon.type.records[weapon.recordId].speed
    end
    local speedMult = settingsDamage:get("weaponSpeedMult")

    Log("Weapon Skill: " .. weaponSkill .. "\n" ..
        "Skill Mult:   " .. skillMult .. "\n" ..
        "Weapon Speed: " .. weaponSpeed .. "\n" ..
        "Speed Mult:   " .. speedMult)

    return skillMult * weaponSkill + speedMult * weaponSpeed
end

local function modifyDamage(attack, stat, initMult, setting)
    if not attack.damage[stat] or attack.damage[stat] <= 0 then return false end

    Log("##### Modifying " .. stat .. " damage #####")

    local damageMult = initMult + settingsDamage:get(setting)

    Log("Raw damage mult:    " .. damageMult)

    damageMult = math.max(damageMult, settingsDamage:get("minMult"))
    damageMult = math.min(damageMult, settingsDamage:get("maxMult"))

    Log("Capped damage mult: " .. damageMult .. "\n" ..
        "Initial damage:     " .. attack.damage[stat])

    attack.damage[stat] = attack.damage[stat] * damageMult

    Log("Final damage:       " .. attack.damage[stat])

    return true
end

function ModifyAttack(attack)
    Log("##### Modifying attack damage #####")

    local initMult = getDamageMult(attack)
    local dmgModified = false
    dmgModified = modifyDamage(attack, "health", initMult, "baseHpCritDmg") or dmgModified
    dmgModified = modifyDamage(attack, "fatigue", initMult, "baseFatCritDmg") or dmgModified
    dmgModified = modifyDamage(attack, "magicka", initMult, "baseMagCritDmg") or dmgModified
    return dmgModified
end
