---@type IDPresenceMap
local TavernNamesVanilla = {
    ['ald-ruhn, ald skar inn'] = true,
    ['ald-ruhn, the rat in the pot'] = true,
    ['balmora, eight plates'] = true,
    ['balmora, lucky lockup'] = true,
    ['balmora, lucky lockup\'s rooftop apartment'] = true,
    ['caldera, shenk\'s shovel'] = true,
    ['dagon fel, end of the world renter rooms'] = true,
    ['dagon fel, the end of the world'] = true,
    ['ebonheart, six fishes'] = true,
    ['ghostgate, tower of dusk lower level'] = true,
    ['molag mar, the pilgrim\'s rest'] = true,
    ['mournhold, the winged guar'] = true,
    ['raven rock, bar'] = true,
    ['sadrith mora, fara\'s hole in the wall'] = true,
    ['sadrith mora, gateway inn'] = true,
    ['sadrith mora, gateway inn, north wing'] = true,
    ['sadrith mora, gateway inn, south wing'] = true,
    ['sadrith mora, gateway inn, west wing'] = true,
    ['solstheim, thirsk'] = true,
    ['suran, desele\'s house of earthly delights'] = true,
    ['suran, desele\'s house of earthly delights basement'] = true,
    ['tel aruhn, plot and plaster'] = true,
    ['tel mora, the covenant'] = true,
    ['vivec, no name club'] = true,
    ['vivec, the flowers of gold'] = true,
    ['vivec, the lizard\'s head'] = true,
    ['suran, suran tradehouse basement'] = true,
    ['mudcrab imports tradehouse'] = true,
    ['maar gan, andus tradehouse'] = true,
    ['tel branora, sethan\'s tradehouse'] = true,
    ['vos, varo tradehouse entrance'] = true,
    ['khuul, thongar\'s tradehouse'] = true,
    ['vos, varo tradehouse storage'] = true,
    ['suran, suran tradehouse'] = true,
    ['gnisis, madach tradehouse'] = true,
    ['seyda neen, arrille\'s tradehouse'] = true,
    ['vos, varo tradehouse'] = true,
    ['caldera, mining bunkhouse'] = true,
}

---@type CellMatchPatterns
local TavernMatches = {
    allowed = {
        'alehouse',
        'club',
        'cornerclub',
        'council club',
        'hostel',
        --- Only match names explicitly ending with `inn`
        ' inn$',
        'pawnbroker',
        'tavern',
        'tradehouse',
    },

    disallowed = {},
}

---@type IDPresenceMap
local TRTavernCells = {

    -- Grasping Fortune???
    -- ['the nest'] = true,
    -- ['unnamed legion bar'] = true,
    -- ['the strider\'s wake'] = true,
    -- ['crystal flower inn'] = true,
    -- ['the moldy horker'] = true,

    -- TR, probably
    ['helnim, mjornir\'s meadhouse'] = true,
    ['hlersis, the leaking spore'] = true,
    ['marog, the swallow\'s nest'] = true,
    ['meralag, the golden glade'] = true,
    ['necrom, pilgrim\'s respite'] = true,
    ['old ebonheart, the empress katariah'] = true,
    ['old ebonheart, legion boarding house'] = true,
    ['old ebonheart, the moth and tiger'] = true,
    ['old ebonheart, the salty futtocks'] = true,
    ['port telvannis, the avenue: west wing'] = true,
    ['port telvannis, the avenue'] = true,
    ['port telvannis, the avenue: east wing'] = true,
    ['port telvannis, the avenue: subterranean balconies'] = true,
    ['sailen, the toiling guar'] = true,
    ['tel gilan, the cliff racer\'s rest'] = true,
    ['tel mothrivra, the glass goblet'] = true,
    ['tel muthada, the note in your eye'] = true,
    ['tel ouada, the magic mudcrab'] = true,
    ['verulas pass, twisted root'] = true,
    ['vhul, the howling hound'] = true,
    ['gah sadrith, the wetstone tavern'] = true,
    ['darvonis, the windbreak hostel: dwellings'] = true,
    ['darvonis, the windbreak hostel'] = true,
    ['llothanis, the water\'s shadow tavern'] = true,
    ['port telvannis, the lost crab tavern'] = true,
    ['nivalis, the black ogre tavern'] = true,
    ['andothren, golden moons club'] = true,
    ['bal foyen, golden moons club'] = true,
    ['armun pass outpost, the guar with no name'] = true,
    ['arvud, lucky shalaasa\'s caravanserai'] = true,
    ['arvud, lucky shalaasa\'s caravanserai: rooms'] = true,
    ['enamor dayn, the gentle velk'] = true,
    ['firewatch, the howling noose'] = true,
    ['firewatch, the queen\'s cutlass'] = true,
    ['silver serpent: cabin'] = true,

    -- Confirmed good

    --cyrodiil--
    ['charach, plaza taverna'] = true,
    ['sunset hotel'] = true,
    ['charach, sunset hotel: pearl suite'] = true,
    ['charach, sunset hotel: opal suite'] = true,
    ['charach, sunset hotel: aquamarine suite'] = true,
    ['charach, sunset hotel: staff lodgings'] = true,
    ['charach, sunset hotel'] = true,
    ['charach, sunset hotel: coral suite'] = true,
    ['charach, old seawater inn'] = true,
    ['anvil, the anchor\'s rest'] = true,
    ['anvil, all flags inn'] = true,
    ['anvil, caravan stop'] = true,
    ['anvil, saint amiel officers\' club: top floor'] = true,
    ['anvil, saint amiel officers\' club'] = true,
    ['anvil, the abecette: inner hall'] = true,
    ['anvil, the abecette: hotel'] = true,
    ['anvil, the abecette: fight pit'] = true,
    ['anvil, the abecette'] = true,
    ['anvil, the abecette: attic'] = true,
    ['brina cross, crossing inn'] = true,
    ['hal sadek, spearmouth inn'] = true,
    ['thresvy, the blind watchtower'] = true,
    --cyrodiil--

    --shotn--
    ['dragonstar west, dragon fountain inn'] = true,
    ['helnim, the red drake'] = true,
    ['karthwasten, the dancing saber'] = true,
    ['karthwasten, the dancing saber: den'] = true,
    ['karthwasten, the droopy mare'] = true,
    ['karthwasten, ruby drake inn'] = true,
    --shotn--

    ---???
    ['ranyon-ruhn, the dancing jug'] = true,
    ['hunted hound inn'] = true,
    ['the inn between'] = true,
    ['aimrah, the sailor\'s inn'] = true,
    ['bosmora, the starlight inn'] = true,
    ['gorne, the emerald haven inn'] = true,
    ['uman, hound\'s rest inn'] = true,
    ['the grey lodge'] = true,
    ['akamora, the laughing goblin'] = true,
    ['akamora, underground bazaar'] = true,
    ['almas thiss, hostel of the crossing'] = true,
    ['almas thirr, limping scrib'] = true,
    ['almas thirr, the pious pirate'] = true,
    ['bal foyen, the dancing cup'] = true,
    ['ruari, daracam\'s tradehouse'] = true,
    ['vhul, tradehouse'] = true,
    ['vhul, tradehouse attic'] = true,
    ['teyn, cirifae\'s tradehouse'] = true,
    ['maar-bani crossing, tradehouse'] = true,
    ['merduibh, rhuma\'s tradehouse'] = true,
    ['hlan oek, hlaalu council company tradehouse'] = true,
    ['ald marak, elval tradehouse'] = true,
    ['haimtir, jhorcian\'s tradehouse'] = true,
    ['andar mok, andalas tradehouse'] = true,
    ['bodrum, varalaryn tradehouse'] = true,
    ['enamor dayn, tradehouse'] = true,
    ['aimrah, communal tradehouse'] = true,
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type ValidPlaylistCallback
local function tavernOrCellRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and (
            (
                playback.rules.cellNameExact(TavernNamesVanilla) or playback.rules.cellNameExact(TRTavernCells)
            )
            or
            (
                playback.rules.cellNameMatch(TavernMatches)
            )
        )
end

---@type S3maphorePlaylist[]
return {
    {
        -- 'Inns and Taverns - Vanilla',
        id = 'ms/cell/taverns',
        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 2,
        randomize = true,

        isValidCallback = tavernOrCellRule,
    },
    -- The original CaptainCreepy pack uses `tavern`, but the DM compatibility pack uses `tavern`
    {
        -- 'Inns and Taverns - Vanilla',
        id = 'ms/cell/tavern',
        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 2,
        randomize = true,

        isValidCallback = tavernOrCellRule,
    },
}
