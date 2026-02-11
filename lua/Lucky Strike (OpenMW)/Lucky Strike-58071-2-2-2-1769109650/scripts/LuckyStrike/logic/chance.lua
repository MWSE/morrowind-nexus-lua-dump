local storage = require('openmw.storage')

require("scripts.LuckyStrike.utils.omw_utils")

local settingsChance = storage.globalSection('SettingsLuckyStrike_chance')

local chanceFormulas = {
    Linear = function(victim, attacker)
        local luck = attacker.type.stats.attributes.luck(attacker)
        local luckMult = settingsChance:get("luckMult")
        local baseChance = settingsChance:get("baseChance")
        local backstabBonus = IsBackHit(victim, attacker, settingsChance:get("actorFov"))
            and settingsChance:get("backstabBonus") or 0

        Log("Luck:           " .. luck.modified .. "\n" ..
            "Luck Mult:      " .. luckMult .. "\n" ..
            "Backstab Bonus: " .. backstabBonus .. "\n" ..
            "Base Chance:    " .. baseChance)

        return (luck.modified * luckMult + backstabBonus + baseChance) / 100
    end,
    Classic = function(victim, attacker)
        local luck = attacker.type.stats.attributes.luck(attacker)

        Log("Luck: " .. luck.modified)

        return (luck.modified / 100) ^ 3 / 2
    end,
}

function GetCritChance(victim, attacker)
    Log("##### Calculating crit chance #####" .. "\n" ..
        "Attacker: " .. attacker.recordId .. "\n" ..
        "Victim:   " .. victim.recordId .. "\n" ..
        "Formula:  " .. settingsChance:get("formula"))

    local formula = chanceFormulas[settingsChance:get("formula")]
    local chance = formula(victim, attacker)

    Log("Raw chance:    " .. chance)

    chance = math.max(chance, settingsChance:get("minChance"))
    chance = math.min(chance, settingsChance:get("maxChance"))

    Log("Capped chance: " .. chance)

    return chance
end
