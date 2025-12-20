---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type IDPresenceMap
local TheGardenCells = {
    ['the garden, tower'] = true,
    ['the garden, corpse fields'] = true,
}

local function theGardenRule()
    return Playback.rules.cellNameExact(TheGardenCells)
end

local function theGardenCombatRule()
    return Playback.state.isInCombat
        and Playback.rules.cellNameExact(TheGardenCells)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'x32/explore',
        priority = PlaylistPriority.CellExact,

        isValidCallback = theGardenRule,
    },
    {
        id = 'x32/combat',
        priority = PlaylistPriority.BattleMod,

        isValidCallback = theGardenCombatRule
    },
    {
        id = 'the nebula',
        priority = PlaylistPriority.CellExact - 10, -- Nasty hack, this should probably be Special priority, but those are broken atm

        tracks = {
            'music/x32/explore/nebula.mp3',
        },

        isValidCallback = function()
            return Playback.state.cellName == 'the nebula between worlds'
        end
    }
}