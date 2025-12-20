---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type CellMatchPatterns
local KilhavenPatterns = {
    allowed = {
        'kilhaven',
    },
}

local TemplePatterns = {
    allowed = {
        'temple of meridia, lower sanctum',
    },
}

local CovePatterns = {
    allowed = {
        'corpse cove',
    },
}

local GundigulPatterns = {
    allowed = {
        'gundigul',
    },
}

---@type ValidPlaylistCallback
local function KilhavenCombatRule()
    return Playback.state.isInCombat
        and Playback.rules.cellNameMatch(KilhavenPatterns)
end

local function TempleCombatRule()
    return Playback.state.isInCombat
        and Playback.rules.cellNameMatch(TemplePatterns)
end

local function CoveCombatRule()
    return Playback.state.isInCombat
        and Playback.rules.cellNameMatch(CovePatterns)
end

local function GundigulCombatRule()
    return Playback.state.isInCombat
        and Playback.rules.cellNameMatch(GundigulPatterns)
end

return {
    {
        id = 'ms/combat/AGB_Golem',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = KilhavenCombatRule,
    },
    {
        id = 'ms/combat/AGB_Priestess',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = TempleCombatRule,
    },
    {
        id = 'ms/combat/AGB_Worm',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = CoveCombatRule,
    },
    {
        id = 'ms/combat/AGB_Ghost',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = GundigulCombatRule,
    },
}
