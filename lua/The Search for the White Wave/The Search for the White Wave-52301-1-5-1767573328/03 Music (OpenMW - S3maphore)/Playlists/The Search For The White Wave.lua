---@type IDPresenceMap
local WhiteWaveCells = {
    ['white wave, hold'] = true,
    ['white wave, cabin'] = true,
    ['sea of ghosts, the white wave'] = true,
    ['sea of ghosts, icy cave'] = true,
}

local function whiteWaveRule(playback)
    return playback.rules.cellNameExact(WhiteWaveCells)
end

local function whiteWaveCombatRule(playback)
    return playback.state.isInCombat
        and playback.rules.cellNameExact(WhiteWaveCells)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'mdww/explore',
        priority = PlaylistPriority.CellExact,

        isValidCallback = whiteWaveRule,
    },
    {
        id = 'mdww/combat',
        priority = PlaylistPriority.BattleMod,

        isValidCallback = whiteWaveCombatRule
    }
}