local PlaylistPriority = require 'doc.playlistPriority'

---@type IDPresenceMap
local AlmalexiaCells = {
    ['mournhold temple: high chapel'] = true,
}

local Almalexia = {
	['almalexia'] =  true,
}

---@type ValidPlaylistCallback
local function almalexiaCellRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.cellNameExact(AlmalexiaCells)
end

local function theWomanHerselfRule(playback)
    return playback.state.isInCombat
        and playback.rules.combatTargetExact(Almalexia)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/almalexia',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = almalexiaCellRule,
    },
	{
        id = 'ms/combat/almalexia',
        priority = 1,
        randomize = true,

        isValidCallback = theWomanHerselfRule,
    }
}
