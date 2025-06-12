---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type CellMatchPatterns
local ShotnCityPatterns = {
    allowed = {
        'karthwasten',
        'dragonstar',
        'karthgad',
        'ruari',
        'uramok',
        'blood paw lodge',
        'even odds inn',
        'mairager',
        'nargozh',
        'bailcnoss',
        'merduibh',
        'haimtir',
        'criaglorc',
        'vorngyd\'s stand',
        'markarth side',
        'fenhru',
        'lugarsh',
        'cairac',
        'beorinhal',
        'fenrald\'s bend',
        'old hrol\'dan'

    },

    disallowed = {
        'sewer',
        'dungeon',
    }
}

---@type ValidPlaylistCallback
local function shotnCityRule()
    return not Playback.state.isInCombat
        and Playback.rules.cellNameMatch(ShotnCityPatterns)
end

---@type ValidPlaylistCallback
local function shotnCombatCityRule()
    return Playback.state.isInCombat
        and Playback.rules.cellNameMatch(ShotnCityPatterns)
end

---@type IDPresenceMap
local ShotnRegions = {
    ['druadach highlands region'] = true,
    ['lorchwuir heath region'] = true,
    ['midkarth region'] = true,
    ['vorndgad forest region'] = true,
    ['sundered hills region'] = true,
    ['solitude forest region'] = true,
    ['vaalstag highlands region'] = true,
    ['grey plains region'] = true,
    ['kilkreath mountains region'] = true,
}

---@type ValidPlaylistCallback
local function shotnRegionRule()
    return not Playback.state.isInCombat
        and Playback.rules.region(ShotnRegions)
end

---@type ValidPlaylistCallback
local function shotnCombatRegionRule()
    return Playback.state.isInCombat
        and Playback.rules.region(ShotnRegions)
end

return {
    {
        id = 'shotn/city',
        priority = PlaylistPriority.City,
        randomize = true,

        isValidCallback = shotnCityRule,
    },
    {
        id = 'shotn/wilds',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = shotnRegionRule,
    },
    {
        id = 'shotn/combat-city',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = shotnCombatCityRule,
    },
    {
        id = 'shotn/combat-wilds',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = shotnCombatRegionRule,
    },
}
