local HlaaluEnemyNames = {
    ['hlaalu guard'] = true,
    ['duke vedam dren'] = true,
    ['nevena ules'] = true,
    ['crassius curio'] = true,
    ['dram bero'] = true,
    ['yngling half-troll'] = true,
    ['ranes ienith'] = true,
    ['navil ienith'] = true,
    ['orvas dren'] = true,
    ['madrale thirith'] = true,
    ['marasa aren'] = true,
    ['sovor trandel'] = true,
    ['thanelen velas'] = true,
    ['vadusa sathryon'] = true,
    ['vurvyn othren'] = true,
    ['telare evos'] = true,
    ['mundrila rindu'] = true,
    ['bothus drals'] = true,
    ['mervis llarel'] = true,
    ['atran oran'] = true,
    ['tholer andas'] = true,
    ['nalvyna balen'] = true,
    ['dreynos helvi'] = true,
    ['ulvys ules'] = true,
    ['bol salvani'] = true,
    ['feldril sathis'] = true,
    ['alvynu llervas'] = true,
    ['belron hlaalu'] = true,
    ['diradeni raran'] = true,
    ['edrano vedas'] = true,
    ['ereven peronys'] = true,
    ['releniah dren'] = true,
    ['saritha hlaalu'] = true,
    ['sodreru hlaalu'] = true,
    ['tereldyn hlaalu'] = true,
    ['ulvo hlaari'] = true,
    ['idros rothrano'] = true,
    ['artisa rethan'] = true,
    ['llaros samalsi'] = true,
    ['athires hlaalu'] = true,
    ['duke fethas hlaalu'] = true,
    ['llirala arys'] = true,
    ['serali beralam'] = true,
    ['nalvos omayn'] = true,
    ['felrar berathi'] = true,
    ['peleri hlaalu'] = true,
    ['ulvys nerano'] = true,
    ['milena farano'] = true,
    ['llevas uvalor'] = true,
}

---@type ValidPlaylistCallback
local function hlaaluEnemyRule(playback)
    return playback.state.isInCombat
        and playback.rules.combatTargetExact(HlaaluEnemyNames)
end

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
local function hlaaluCellRule(playback)
    return not playback.state.isInCombat
        and (
            playback.rules.cellNameExact(HlaaluCatacombNames)
            or playback.rules.cellNameMatch(HlaaluCellNames)
        )
end

local PlaylistPriority = require 'doc.playlistPriority'

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

        isValidCallback = hlaaluEnemyRule,
    }
}
