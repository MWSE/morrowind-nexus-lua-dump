---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type CellMatchPatterns
local HlaaluCellNames = {
    allowed = {
        "balmora",
        "suran",
        "gnaar mok",
        "hla oad",
        "rethan manor",
        "arvel plantation",
        "arano plantation",
        "dren plantation",
        "omani manor",
        "ules manor",
        "gro-bagrat plantation",
        "narsis",
        "bal foyen",
        "hlan oek",
        "hlerynhul",
        "othmura",
        "shipal-sharai",
        "arvud",
        "gol mok",
        "idathren",
        "indal-ruhn",
        "menaan",
        "omaynis",
        "sadrathim",
        "mundrethi plantation",
        "oran plantation",
        "vathras plantation",

    },
    disallowed = {
        "sewers",
        "catacombs",
    },
}

---@type IDPresenceMap
local HlaaluCatacombNames = {
    ['narsis, catacombs: gateway'] = true,
    ['narsis, catacombs: chamber of narsara'] = true,
}

---@type ValidPlaylistCallback
local function hlaaluCellRule()
    return not Playback.state.isInCombat
        and (
            Playback.rules.cellNameExact(HlaaluCatacombNames)
            or Playback.rules.cellNameMatch(HlaaluCellNames)
        )
end

---@type NumericPresenceMap
local hlaaluFactionData = {
    hlaalu = { min = 1 },
}

---@type ValidPlaylistCallback
local function hlaaluFactionRule()
    return Playback.state.isInCombat
        and Playback.rules.combatTargetFaction(hlaaluFactionData)
end

---@type S3maphorePlaylist[]
return {
    {
        -- 'MUSE - Hlaalu Settlement',
        id = 'ms/cell/hlaalu',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = hlaaluCellRule,
    },
    {
        -- 'MUSE - Hlaalu Enemies',
        id = 'ms/combat/hlaalu',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = hlaaluFactionRule,
    }
}
