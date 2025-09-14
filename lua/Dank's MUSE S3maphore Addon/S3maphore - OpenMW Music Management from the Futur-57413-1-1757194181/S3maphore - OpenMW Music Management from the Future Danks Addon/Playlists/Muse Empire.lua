---@type IDPresenceMap
local EmpireEnemyNames = {
    ['guard'] = true,
    ['imperial guard'] = true,
    ['guard captain'] = true,
    ['duke\'s guard'] = true,
    ['company guard'] = true,
    ['varus vantinius'] = true,
    ['arius rulician'] = true,
    ['oritius maro'] = true,
    ['lugrub gro-ogdum'] = true,
    ['honthjolf'] = true,
    ['furius acilius'] = true,
    ['cavortius albuttian'] = true,
    ['imsin the dreamer'] = true,
    ['frald the white'] = true,
    ['captain falx carius'] = true,
    ['darius'] = true,
    ['radd hard-heart'] = true,
    ['angoril'] = true,
    ['caius cosades'] = true,
    ['gildan'] = true,
    ['nine-toes'] = true,
    ['rithleen'] = true,
    ['tyermallin'] = true,
    ['surane leoriane'] = true,
    ['elone'] = true,
    ['sjorvar horse-mouth'] = true,
    ['carnius magius'] = true,
    ['falco galenus'] = true,
    ['vycius pitio'] = true,
    ['thromil rufus'] = true,
    ['antonius rato'] = true,
    ['rojanna jades'] = true,
    ['servas capris'] = true,
    ['ereven baryl'] = true,
    ['maurrisha'] = true,
    ['olfver steel-skin'] = true,
    ['caecalia victrix'] = true,
    ['madala ceno'] = true,
    ['doure'] = true,
    ['aquilinius'] = true,
    ['destarmion'] = true,
    ['idra uvalen'] = true,
    ['kuvir shoal-flare'] = true,
    ['potemus marolus'] = true,
    ['kventus lucilius'] = true,
    ['tibera rone'] = true,
    ['lora avis'] = true,
    ['zaren hammebenat'] = true,
    ['rogatus cipius'] = true,
    ['cano'] = true,
    ['aetia nemesia'] = true,
    ['cassynderia lys'] = true,
}

---@type ValidPlaylistCallback
local function empireEnemyRule(playback)
    return playback.rules.combatTargetExact(EmpireEnemyNames)
end

---@type CellMatchPatterns
local EmpireCellMatches = {
    allowed = {
        'caldera',
        'ebonheart',
        'pelagiad',
        'seyda neen',
        'moonmoth',
        'darius',
        'firemoth',
        'frostmoth',
        'buckmoth',
        'hawkmoth',
        'wolverine hall',
        'raven rock',
        'old ebonheart',
        'ebon tower',
        'firewatch',
        'helnim',
        'nivalis',
        'ancylis',
        'umbermoth',
        'windmoth',
        'stormgate pass',
        'septim\'s gate pass',
        'dustmoth',
        'servas',
    },

    disallowed = {
        'mage\'s guild',
        'fighter\'s guild',
        'guild of mages',
        'guild of fighters',
        'sewers',
    },
}

--- Yes, really, these *are* meant to be different playlists
---@type CellMatchPatterns
local ImperialCellMatches = {
    allowed = {
        'caldera',
        'ebonheart',
        'pelagiad',
    },

    disallowed = {
        'sewers',
        'old ebonheart',
    },
}

---@type ValidPlaylistCallback
local function empireCellRule(playback)
    return playback.rules.cellNameMatch(EmpireCellMatches)
end

---@type ValidPlaylistCallback
local function imperialCellRule(playback)
    return playback.rules.cellNameMatch(ImperialCellMatches)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        -- 'MUSE - Empire Settlement',
        id = 'ms/cell/empire',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = empireCellRule
    },
    {
        -- 'MUSE - Empire Settlement',
        id = 'ms/cell/imperial',
        priority = PlaylistPriority.Faction - 1,
        randomize = true,

        isValidCallback = imperialCellRule
    },
    {
        -- 'MUSE - Empire Enemies',
        id = 'ms/combat/empire',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = empireEnemyRule
    },
}
