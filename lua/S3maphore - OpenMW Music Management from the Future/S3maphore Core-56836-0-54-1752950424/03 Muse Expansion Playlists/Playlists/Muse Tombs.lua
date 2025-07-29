---@type IDPresenceMap
local TombEnemyNames = {
    ['ancestor ghost'] = true,
    ['ancestor guardian'] = true,
    ['gateway haunt'] = true,
    ['ghost of galos heleran'] = true,
    ['kanit ashurnisammis'] = true,
    ['mansilamat vabdas'] = true,
    ['wraith of sul-senipul'] = true,
    ['bonelord'] = true,
    ['bonewalker'] = true,
    ['lesser bonewalker'] = true,
    ['greater bonewalker'] = true,
    ['beldoh the undying'] = true,
    ['crippled skeleton'] = true,
    ['skeleton'] = true,
    ['skeleton archer'] = true,
    ['skeleton champion'] = true,
    ['skeleton war-wizard'] = true,
    ['skeleton warrior'] = true,
    ['worm lord'] = true,
    ['lich'] = true,
    ['profane acolyte'] = true,
    ['gedna relvel'] = true,
    ['barilzar'] = true,
    ['greater ancestor ghost'] = true,
    ['variner\'s ghost'] = true,
    ['bonewolf'] = true,
    ['draugr'] = true,
    ['valbrandr draugr'] = true,
    ['draugr lord aesliip'] = true,
    ['skeleton berserker'] = true,
    ['skeleton pirate'] = true,
    ['skeleton pirate captain'] = true,
    ['greater skeleton champion'] = true,
    ['plaguebearer bonewalker'] = true,
    ['greater plaguebearer bonewalker'] = true,
    ['the fiery horror'] = true,
    ['lord drolar'] = true,
    ['nelgirion the venerable'] = true,
    ['pharan the black'] = true,
    ['mummy'] = true,
    ['plaguebearer skeleton champion'] = true,
    ['plaguebearer skeleton'] = true,
    ['skeletal guardian'] = true,
    ['eternal guardian'] = true,
    ['plaguebearer bonelord'] = true,
    ['bonelord warder'] = true,
    ['procession bonewalker'] = true,
    ['indoril nereval'] = true,
    ['revered bonewalker'] = true,
}

---@type ValidPlaylistCallback
local function tombEnemyRule(playback)
    return playback.rules.combatTargetExact(TombEnemyNames)
end

---@type CellMatchPatterns
local TombCellMatches = {
    allowed = {
        'ancestral tomb',
        'gedna relvel\'s tomb',
        'abandoned crypt',
        'barrow',
        'burial',
        'catacombs',
    },

    disallowed = {},
}

---@type IDPresenceMap
local TombCellExclusions = {
    ['narsis, catacombs: gateway'] = true,
    ['narsis, catacombs: chamber of narsara'] = true,
}

---@type ValidPlaylistCallback
local function tombCellRule(playback)
    return not playback.rules.cellNameExact(TombCellExclusions)
        and playback.rules.cellNameMatch(TombCellMatches)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        -- 'MUSE - Tomb Cells',
        id = 'ms/cell/tomb',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = tombCellRule,
    },
    {
        -- 'MUSE - Tomb Enemies',
        id = 'ms/combat/tomb',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = tombEnemyRule,
    },
}
