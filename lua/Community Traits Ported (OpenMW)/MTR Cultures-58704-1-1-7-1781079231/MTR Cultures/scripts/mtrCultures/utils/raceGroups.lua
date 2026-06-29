local raceGroups = {}

raceGroups.isKhajiit = function(player)
    ---@diagnostic disable-next-line: undefined-field
    local playerRace = player.type.records[player.recordId].race
    local whitelist = {
        ["khajiit"] = true,
        ["t_els_cathay"] = true,
        ["t_els_cathay-raht"] = true,
        ["t_els_dagi-raht"] = true,
        ["t_els_ohmes"] = true,
        ["t_els_ohmes-raht"] = true,
        ["t_els_suthay"] = true,
    }
    return whitelist[playerRace]
end

raceGroups.isOrc = function(player)
    ---@diagnostic disable-next-line: undefined-field
    local playerRace = player.type.records[player.recordId].race
    local whitelist = {
        ["orc"] = true,
        ["t_mw_malahk_orc"] = true,
    }
    return whitelist[playerRace]
end

return raceGroups
