local PlaylistPriority = require 'doc.playlistPriority'

---@type CellMatchPatterns
local TelvanniMatches = {
    allowed = {
        'sadrith mora',
        'tel aruhn',
        'tel branora',
        'tel mora',
        'tel fyr',
        'tel vos',
        'vos',
        'tel uvirith',
        'port telvannis',
        'llothanis',
        'tel aranyon',
        'ranyon-ruhn',
        'alt bosara',
        'andar mok',
        'ashamul',
        'bahrammu',
        'baldrahn',
        'gah sadrith',
        'hla bulor',
        'tel gilan',
        'tel mothrivra',
        'tel muthada',
        'tel ouada',
        'sadas plantation',
        'tel rivus',
    },

    disallowed = {
        'sewers',
    },
}

---@type IDPresenceMap
local TelvanniCombatTargets = {
    ['telvanni guard'] = true,
    ['gothren'] = true,
    ['neloth'] = true,
    ['therana'] = true,
    ['dratha'] = true,
    ['aryon'] = true,
    ['galas drenim'] = true,
    ['baladas demnevanni'] = true,
    ['llarar bereloth'] = true,
    ['tiram gadar'] = true,
    ['milyn faram'] = true,
    ['divath fyr'] = true,
    ['faves andas'] = true,
    ['tirer belvayn'] = true,
    ['vaerin'] = true,
    ['jula minthri'] = true,
    ['areth morvayn'] = true,
    ['fervas shulisa'] = true,
    ['malvas relvani'] = true,
    ['nethan marys'] = true,
    ['nevrile omayn'] = true,
    ['norahin darys'] = true,
    ['mithras'] = true,
    ['faruna'] = true,
    ['rathra'] = true,
    ['nira uldram'] = true,
    ['rilvin dral'] = true,
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/telvanni',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.rules.cellNameMatch(TelvanniMatches)
        end
    },
    {
        id = 'ms/combat/telvanni',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = function(playback)
            return playback.state.isInCombat
                and playback.rules.combatTargetExact(TelvanniCombatTargets)
        end,
    }
}
