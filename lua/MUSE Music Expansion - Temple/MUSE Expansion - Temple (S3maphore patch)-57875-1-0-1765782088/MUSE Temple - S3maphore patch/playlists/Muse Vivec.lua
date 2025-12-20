local PlaylistPriority = require 'doc.playlistPriority'

---@type IDPresenceMap
local VivecCells = {
    ['vivec, palace of vivec'] = true,
}

local Vivec = {
	['vivec'] =  true,
}

---@type ValidPlaylistCallback
local function vivecCellRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.cellNameExact(VivecCells)
end

local function theOtherManHimselfRule(playback)
    return playback.state.isInCombat
        and playback.rules.combatTargetExact(Vivec)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/vivec',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = vivecCellRule,
    },
	{
        id = 'ms/combat/vivec',
        priority = 1,
        randomize = true,

        isValidCallback = theOtherManHimselfRule,
    }
}
