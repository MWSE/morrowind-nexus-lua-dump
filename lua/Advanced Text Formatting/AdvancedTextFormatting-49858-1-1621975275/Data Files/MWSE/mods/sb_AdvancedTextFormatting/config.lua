local config = {}

config.weatherTypes = {
    [0] = "Clear",
    [1] = "Cloudy",
    [2] = "Foggy",
    [3] = "Overcast",
    [4] = "Rain",
    [5] = "Thunder",
    [6] = "Ash",
    [7] = "Blight",
    [8] = "Snow",
    [9] = "Blizzard"
}

------------------------------------------------------------------------------------------------------------------------

function config.GetDate(index)
    local lastTwo, lastOne = index % 100, index % 10
    if lastTwo > 3 and lastTwo < 21 then
        return tostring(index) .. "th"
    end
    if lastOne == 1 then
        return tostring(index) .. "st"
    end
    if lastOne == 2 then
        return tostring(index) .. "nd"
    end
    if lastOne == 3 then
        return tostring(index) .. "rd"
    end
    return tostring(index) .. "th"
end

function config.GetMonthName(index)
    index = tonumber(index)
    if (index >= 0 and index <= 11) then
        return tes3.findGMST(index).value
    end
    return "nil"
end

function config.GetClassName(index)
    return tes3.dataHandler.nonDynamicData.classes[index].name or "nil"
end

function config.GetSkillName(index)
    return tes3.dataHandler.nonDynamicData.skills[index].name or "nil"
end

function config.GetSpellName(index)
    return tes3.dataHandler.nonDynamicData.spells[index].name or "nil"
end

function config.GetMagicEffectName(index)
    for i, v in ipairs(tes3.dataHandler.nonDynamicData.magicEffects) do
        if (i == tonumber(index)) then
            return v.name
        end
    end
    return "nil"
end

function config.GetFactionName(index)
    return tes3.dataHandler.nonDynamicData.factions[index].name or "nil"
end

function config.GetFactionRankName(faction, index)
    return tes3.dataHandler.nonDynamicData.factions[faction]:getRankName(index) or "nil"
end

function config.GetRaceName(index)
    return tes3.dataHandler.nonDynamicData.races[index].name or "nil"
end

function config.GetBirthsignName(index)
    return tes3.dataHandler.nonDynamicData.birthsigns[index].name or "nil"
end

function config.GetWeather(index)

    return config.weatherTypes[tonumber(index)] or "nil"
end

------------------------------------------------------------------------------------------------------------------------

function config.GetPlayerName()
    return tes3.player.object.name
end

function config.GetPlayerLevel()
    return tes3.player.object.level
end

function config.GetPlayerRace()
    return tes3.player.object.race.name
end

function config.GetPlayerClass()
    return tes3.player.object.class.name
end

function config.GetPlayerSkill(index)
    return tes3.mobilePlayer.skills[index].current
end

function config.GetPlayerBirthsign()
    return tes3.mobilePlayer.birthsign.name
end

function config.GetPlayerSex()
    return tes3.player.object.female == true and "female" or "male"
end

function config.GetPlayerClothing(index)
    local clothing = tes3.getEquippedItem { actor = tes3.player, type = 1414483011, slot = index }.object or nil
    return clothing and clothing.name or "nil"
end

function config.GetPlayerArmour(index)
    local armour = tes3.getEquippedItem { actor = tes3.player, type = 1330467393, slot = index }.object or nil
    return armour and armour.name or "nil"
end

function config.GetPlayerWeapon(index)
    local weapon = tes3.getEquippedItem { actor = tes3.player, type = 1346454871, slot = index }.object or nil
    return weapon and weapon.name or "nil"
end

function config.GetPlayerFactionRank(index)
    local faction = tes3.dataHandler.nonDynamicData.factions[index]
    return faction.playerJoined == true and config.GetFactionRankName(index, faction.playerRank) or "nil"
end

function config.GetPlayerGold()
    return tes3.getPlayerGold()
end

------------------------------------------------------------------------------------------------------------------------

function config.GetThisDay()
    return config.GetDate(tes3.getGlobal("Day"))
end

function config.GetThisMonth()
    return config.GetMonthName(tes3.getGlobal("Month"))
end

function config.GetThisYear()
    return tes3.getGlobal("Year")
end

function config.GetThisYearTh()
    return config.GetDate(tes3.getGlobal("Year"))
end

function config.GetThisEra()
    return "3E"
end

function config.GetCurrentWeather()
    return config.weatherTypes[tes3.worldController.weatherController.currentWeather.index] or "nil"
end

------------------------------------------------------------------------------------------------------------------------

function config.GetGlobal(name)
    return tes3.getGlobal(name) or "nil"
end

function config.ToUppercase(value)
    return value:upper()
end

function config.ToLowercase(value)
    return value:lower()
end

return config