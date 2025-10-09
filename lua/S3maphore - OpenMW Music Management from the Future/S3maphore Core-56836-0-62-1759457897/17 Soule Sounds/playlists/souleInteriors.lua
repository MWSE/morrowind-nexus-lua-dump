---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type string[]
local BarrowCavePatterns = {
    'furn_bm_t',
    'in_bm_t_',
    'in_bm_tomb',
    '_rock_bm',
    't_nor_dngbarrow'
}

---@type ValidPlaylistCallback
local function barrowCaveTilesRule()
    return not Playback.state.cellIsExterior
        and Playback.rules.staticMatch(BarrowCavePatterns)
end

---@type ValidPlaylistCallback
local function dwemerCellRule()
    return not Playback.state.cellIsExterior
        and Playback.rules.staticExact(Tilesets.Dwemer)
end

---@type IDPresenceMap
local DaedricCellNames = {
    ['addadshashanammu, shrine'] = true,
    ['ald daedroth, antechamber'] = true,
    ['ald daedroth, inner shrine'] = true,
    ['ald daedroth, left wing'] = true,
    ['ald daedroth, outer shrine'] = true,
    ['ald daedroth, right wing'] = true,
    ['ald sotha, lower level'] = true,
    ['ald sotha, shrine'] = true,
    ['ald sotha, upper level'] = true,
    ['almurbalarammi, shrine'] = true,
    ['ashalmawia, shrine, sunken vaults'] = true,
    ['ashalmawia, shrine'] = true,
    ['ashalmimilkala, shrine'] = true,
    ['ashunartes, shrine'] = true,
    ['ashurnibibi, shrine'] = true,
    ['assalkushalit, shrine'] = true,
    ['assarnatamat, shrine'] = true,
    ['assurdirapal, inner shrine'] = true,
    ['assurdirapal, shrine'] = true,
    ['assurnabitashpi, shrine'] = true,
    ['bal fell, east wing'] = true,
    ['bal fell, inner shrine'] = true,
    ['bal fell, outer shrine'] = true,
    ['bal fell, west wing'] = true,
    ['bal ur, shrine'] = true,
    ['bal ur, underground'] = true,
    ['dubdilla, uncharted caverns, lower'] = true,
    ['dushariran, shrine'] = true,
    ['ebernanit, shrine'] = true,
    ['esutanamus, shrine'] = true,
    ['forgotten vaults of anudnabia, forge of hilbongard'] = true,
    ['ibar-dad'] = true,
    ['kaushtarari, shrine'] = true,
    ['kora-dur'] = true,
    ['kushtashpi, shrine'] = true,
    ['maelkashishi, shrine, forgotten galleries'] = true,
    ['maelkashishi, shrine'] = true,
    ['magas volar'] = true,
    ['norenen-dur, basilica of divine whispers'] = true,
    ['norenen-dur, citadel of myn dhrur'] = true,
    ['norenen-dur, the grand stair'] = true,
    ['norenen-dur, the wailingdelve'] = true,
    ['norenen-dur'] = true,
    ['omaren ancestral tomb'] = true,
    ['onnissiralis, shrine'] = true,
    ['ramimilk, shrine'] = true,
    ['shashpilamat, shrine'] = true,
    ['shashpilamat'] = true,
    ['shrine of azura'] = true,
    ['solstheim, mortrag glacier: entry'] = true,
    ['solstheim, mortrag glacier: huntsman\'s hall'] = true,
    ['solstheim, mortrag glacier: inner ring'] = true,
    ['tusenend, shrine'] = true,
    ['ularradallaku, shrine'] = true,
    ['yansirramus, shrine'] = true,
    ['yasammidan, shrine'] = true,
    ['zaintiraris, shrine'] = true,
    ['zergonipal, shrine'] = true,
}

---@type CellMatchPatterns
local EidolonCellMatches = {
    allowed = {
        'the eidolon of purity',
    },
    disallowed = {},
}

---@type ValidPlaylistCallback
local function daedricCellRule()
    return not Playback.state.cellIsExterior
        and (
            Playback.rules.staticExact(Tilesets.Daedric)
            or Playback.rules.cellNameExact(DaedricCellNames)
            or Playback.rules.cellNameMatch(EidolonCellMatches)

        )
end

---@type string[]
local IceCavePatterns = {
    'bm_ic_',
    -- 'bm_ic_rock',
    -- 'bm_ic_room',
    -- 'bm_ic_stalag'
}

---@type ValidPlaylistCallback
local function iceCaveTilesRule()
    return not Playback.state.cellIsExterior
        and Playback.rules.staticMatch(IceCavePatterns)
end

---@type IDPresenceMap
local sewerCellNames = {
    ['falasmaryon, sewers'] = true,
    ['hlormaren, sewers'] = true,
    ['kogoruhn, nabith waterway'] = true,
    ['molag mar, underworks'] = true,
    ['vivec, arena underworks'] = true,
    ['vivec, foreign quarter underworks'] = true,
    ['vivec, hall underworks'] = true,
    ['vivec, hlaalu underworks'] = true,
    ['vivec, redoran underworks'] = true,
    ['vivec, st. delyn underworks'] = true,
    ['vivec, st. olms underworks'] = true,
    ['vivec, telvanni underworks'] = true,
    ['vivec, puzzle canal, level 1'] = true,
    ['vivec, puzzle canal, level 2'] = true,
    ['vivec, puzzle canal, level 3'] = true,
    ['vivec, puzzle canal, level 4'] = true,
    ['vivec, puzzle canal, level 5'] = true,
}

---@type CellMatchPatterns
local sewerMatches = {
    allowed = {
        'sewers',
    },

    disallowed = {},
}

---@type ValidPlaylistCallback
local function sewerCellRule()
    return not Playback.state.cellIsExterior
        and
        (
            Playback.rules.cellNameExact(sewerCellNames)
            or
            Playback.rules.cellNameMatch(sewerMatches)
        )
end

-- ---@type IDPresenceMap
-- local TombCellNames = {
--     ['alas ancestral tomb'] = true,
--     ['ald redaynia, tower'] = true,
--     ['ald-ruhn, temple'] = true,
--     ['alen ancestral tomb'] = true,
--     ['andalen ancestral tomb'] = true,
--     ['andalor ancestral tomb'] = true,
--     ['andas ancestral tomb'] = true,
--     ['andavel ancestral tomb'] = true,
--     ['andrano ancestral tomb'] = true,
--     ['andrethi ancestral tomb'] = true,
--     ['andules ancestral tomb'] = true,
--     ['aralen ancestral tomb'] = true,
--     ['aran ancestral tomb'] = true,
--     ['arano ancestral tomb'] = true,
--     ['arenim ancestral tomb'] = true,
--     ['arethan ancestral tomb'] = true,
--     ['aryon ancestral tomb'] = true,
--     ['arys ancestral tomb'] = true,
--     ['ashmelech'] = true,
--     ['assernerairan, shrine'] = true,
--     ['balmora, temple'] = true,
--     ['baram ancestral tomb'] = true,
--     ['beran ancestral tomb'] = true,
--     ['dareleth ancestral tomb'] = true,
--     ['dralas ancestral tomb'] = true,
--     ['drath ancestral tomb'] = true,
--     ['dreloth ancestral tomb'] = true,
--     ['drethan ancestral tomb'] = true,
--     ['drinith ancestral tomb'] = true,
--     ['dulo ancestral tomb'] = true,
--     ['fadathram ancestral tomb'] = true,
--     ['falas ancestral tomb'] = true,
--     ['favel ancestral tomb'] = true,
--     ['ghostgate, tower of dawn lower level'] = true,
--     ['ghostgate, tower of dawn'] = true,
--     ['ghostgate, tower of dusk lower level'] = true,
--     ['ghostgate, tower of dusk'] = true,
--     ['gimothran ancestral tomb'] = true,
--     ['ginith ancestral tomb'] = true,
--     ['gnisis, arvs-drelen'] = true,
--     ['gnisis, temple'] = true,
--     ['hanud, tower'] = true,
--     ['hanud'] = true,
--     ['helan ancestral tomb'] = true,
--     ['helas ancestral tomb'] = true,
--     ['heleran ancestral tomb'] = true,
--     ['heran ancestral tomb'] = true,
--     ['hlaalu ancestral tomb'] = true,
--     ['hleran ancestral tomb'] = true,
--     ['hlervi ancestral tomb'] = true,
--     ['hlervu ancestral tomb'] = true,
--     ['holamayan monastery'] = true,
--     ['ibishammus, shrine'] = true,
--     ['ienith ancestral tomb'] = true,
--     ['ihinipalit, shrine'] = true,
--     ['indalen ancestral tomb'] = true,
--     ['indaren ancestral tomb'] = true,
--     ['llando ancestral tomb'] = true,
--     ['lleran ancestral tomb'] = true,
--     ['llervu ancestral tomb'] = true,
--     ['mababi'] = true,
--     ['maren ancestral tomb'] = true,
--     ['marvani ancestral tomb'] = true,
--     ['mawia'] = true,
--     ['molag mar, armigers stronghold'] = true,
--     ['molag mar, canalworks'] = true,
--     ['molag mar, redoran stronghold'] = true,
--     ['molag mar, saetring the nord: smith'] = true,
--     ['molag mar, st. veloth\'s hostel'] = true,
--     ['molag mar, temple'] = true,
--     ['molag mar, the pilgrim\'s rest'] = true,
--     ['molag mar, vasesius viciulus: trader'] = true,
--     ['molag mar, waistworks'] = true,
--     ['nelas ancestral tomb'] = true,
--     ['nerano ancestral tomb'] = true,
--     ['norvayn ancestral tomb'] = true,
--     ['odirniran, tower'] = true,
--     ['odirniran'] = true,
--     ['omalen ancestral tomb'] = true,
--     ['omaren ancestral tomb'] = true,
--     ['orethi ancestral tomb'] = true,
--     ['othrelas ancestral tomb'] = true,
--     ['randas ancestral tomb'] = true,
--     ['ravel ancestral tomb'] = true,
--     ['raviro ancestral tomb'] = true,
--     ['redas ancestral tomb'] = true,
--     ['releth ancestral tomb'] = true,
--     ['reloth ancestral tomb'] = true,
--     ['rethandus ancestral tomb'] = true,
--     ['rothan ancestral tomb'] = true,
--     ['sadryon ancestral tomb'] = true,
--     ['salothan ancestral tomb'] = true,
--     ['salothran ancestral tomb'] = true,
--     ['salvel ancestral tomb'] = true,
--     ['samarys ancestral tomb'] = true,
--     ['sandas ancestral tomb'] = true,
--     ['sandus ancestral tomb'] = true,
--     ['sanni'] = true,
--     ['sarano ancestral tomb'] = true,
--     ['saren ancestral tomb'] = true,
--     ['sarethi ancestral tomb'] = true,
--     ['sarys ancestral tomb'] = true,
--     ['savel ancestral tomb'] = true,
--     ['senim ancestral tomb'] = true,
--     ['seran ancestral tomb'] = true,
--     ['serano ancestral tomb'] = true,
--     ['sethan ancestral tomb'] = true,
--     ['shallit'] = true,
--     ['shara'] = true,
--     ['shishara'] = true,
--     ['shishi'] = true,
--     ['sulipund'] = true,
--     ['suran, suran temple'] = true,
--     ['telvayn ancestral tomb'] = true,
--     ['thalas ancestral tomb'] = true,
--     ['tharys ancestral tomb'] = true,
--     ['thelas ancestral tomb'] = true,
--     ['thiralas ancestral tomb'] = true,
--     ['toddtest'] = true,
--     ['tukushapal, sepulcher'] = true,
--     ['tukushapal'] = true,
--     ['uveran ancestral tomb'] = true,
--     ['vandus ancestral tomb'] = true,
--     ['vas, entry level'] = true,
--     ['vas, tower'] = true,
--     ['velas ancestral tomb'] = true,
--     ['veloth ancestral tomb'] = true,
--     ['venim ancestral tomb'] = true,
--     ['verelnim ancestral tomb'] = true,
--     ['vivec, agrippina herennia: clothier'] = true,
--     ['vivec, alusaron: smith'] = true,
--     ['vivec, andilu drothan: alchemist'] = true,
--     ['vivec, arena canalworks'] = true,
--     ['vivec, arena fighters quarters'] = true,
--     ['vivec, arena fighters training'] = true,
--     ['vivec, arena hidden area'] = true,
--     ['vivec, arena holding cells'] = true,
--     ['vivec, arena storage'] = true,
--     ['vivec, arena waistworks'] = true,
--     ['vivec, aurane frernis: apothecary'] = true,
--     ['vivec, black shalk cornerclub'] = true,
--     ['vivec, canon offices'] = true,
--     ['vivec, canon quarters'] = true,
--     ['vivec, curio manor'] = true,
--     ['vivec, dralor manor'] = true,
--     ['vivec, elven nations cornerclub'] = true,
--     ['vivec, foreign quarter canalworks'] = true,
--     ['vivec, foreign quarter lower waistworks'] = true,
--     ['vivec, foreign quarter tomb'] = true,
--     ['vivec, foreign quarter upper waistworks'] = true,
--     ['vivec, guild of fighters'] = true,
--     ['vivec, guild of mages'] = true,
--     ['vivec, hall of justice secret library'] = true,
--     ['vivec, hall of justice'] = true,
--     ['vivec, hall of wisdom'] = true,
--     ['vivec, high fane'] = true,
--     ['vivec, hlaalu alchemist'] = true,
--     ['vivec, hlaalu ancestral vaults'] = true,
--     ['vivec, hlaalu canalworks'] = true,
--     ['vivec, hlaalu edryno arethi\'s house'] = true,
--     ['vivec, hlaalu general goods'] = true,
--     ['vivec, hlaalu pawnbroker'] = true,
--     ['vivec, hlaalu prison cells'] = true,
--     ['vivec, hlaalu temple'] = true,
--     ['vivec, hlaalu treasury'] = true,
--     ['vivec, hlaalu urandile selandas'] = true,
--     ['vivec, hlaalu vaults'] = true,
--     ['vivec, hlaalu waistworks'] = true,
--     ['vivec, hlaalu weaponsmith'] = true,
--     ['vivec, hlaren residence'] = true,
--     ['vivec, jeanne: trader'] = true,
--     ['vivec, jobasha\'s rare books'] = true,
--     ['vivec, j\'rasha: healer'] = true,
--     ['vivec, justice offices'] = true,
--     ['vivec, library of vivec'] = true,
--     ['vivec, lucretinaus olcinius: trader'] = true,
--     ['vivec, mevel fererus: trader'] = true,
--     ['vivec, milo\'s quarters'] = true,
--     ['vivec, miun-gei: enchanter'] = true,
--     ['vivec, no name club'] = true,
--     ['vivec, office of the watch'] = true,
--     ['vivec, ordinator barracks'] = true,
--     ['vivec, puzzle canal, center'] = true,
--     ['vivec, ralen tilvur: smith'] = true,
--     ['vivec, redoran ancestral vaults'] = true,
--     ['vivec, redoran canalworks'] = true,
--     ['vivec, redoran hlavora sadas'] = true,
--     ['vivec, redoran prison cells'] = true,
--     ['vivec, redoran scout & drillmaster'] = true,
--     ['vivec, redoran smith'] = true,
--     ['vivec, redoran temple shrine'] = true,
--     ['vivec, redoran trader'] = true,
--     ['vivec, redoran treasury'] = true,
--     ['vivec, redoran vaults'] = true,
--     ['vivec, redoran waistworks'] = true,
--     ['vivec, saren manor'] = true,
--     ['vivec, simine fralinie: bookseller'] = true,
--     ['vivec, st. delyn canal north-one'] = true,
--     ['vivec, st. delyn canal north-three'] = true,
--     ['vivec, st. delyn canal north-two'] = true,
--     ['vivec, st. delyn canal south-one'] = true,
--     ['vivec, st. delyn canal south-three'] = true,
--     ['vivec, st. delyn canal south-two'] = true,
--     ['vivec, st. delyn canalworks'] = true,
--     ['vivec, st. delyn glassworker\'s hall'] = true,
--     ['vivec, st. delyn potter\'s hall'] = true,
--     ['vivec, st. delyn storage'] = true,
--     ['vivec, st. delyn waist north-one'] = true,
--     ['vivec, st. delyn waist north-two'] = true,
--     ['vivec, st. delyn waist south-one'] = true,
--     ['vivec, st. delyn waist south-two'] = true,
--     ['vivec, st. delyn waistworks'] = true,
--     ['vivec, st. olms brewers and fishmongers hall'] = true,
--     ['vivec, st. olms canal north-one'] = true,
--     ['vivec, st. olms canal north-three'] = true,
--     ['vivec, st. olms canal north-two'] = true,
--     ['vivec, st. olms canal south-one'] = true,
--     ['vivec, st. olms canal south-three'] = true,
--     ['vivec, st. olms canal south-two'] = true,
--     ['vivec, st. olms canalworks'] = true,
--     ['vivec, st. olms farmers and laborers hall'] = true,
--     ['vivec, st. olms haunted manor'] = true,
--     ['vivec, st. olms storage'] = true,
--     ['vivec, st. olms tailors and dyers hall'] = true,
--     ['vivec, st. olms tanners and miners hall'] = true,
--     ['vivec, st. olms temple'] = true,
--     ['vivec, st. olms upper north-one'] = true,
--     ['vivec, st. olms upper north-two'] = true,
--     ['vivec, st. olms upper south-one'] = true,
--     ['vivec, st. olms waist north-one'] = true,
--     ['vivec, st. olms waist north-two'] = true,
--     ['vivec, st. olms waist south-one'] = true,
--     ['vivec, st. olms waist south-two'] = true,
--     ['vivec, st. olms waistworks'] = true,
--     ['vivec, st. olms yngling manor basement'] = true,
--     ['vivec, st. olms yngling manor'] = true,
--     ['vivec, telvanni alchemist'] = true,
--     ['vivec, telvanni apothecary'] = true,
--     ['vivec, telvanni canalworks'] = true,
--     ['vivec, telvanni enchanter'] = true,
--     ['vivec, telvanni mage'] = true,
--     ['vivec, telvanni monster lab'] = true,
--     ['vivec, telvanni prison cells'] = true,
--     ['vivec, telvanni sorcerer'] = true,
--     ['vivec, telvanni temple'] = true,
--     ['vivec, telvanni tower'] = true,
--     ['vivec, telvanni upper storage'] = true,
--     ['vivec, telvanni vault'] = true,
--     ['vivec, telvanni waistworks'] = true,
--     ['vivec, temporary telvanni housing'] = true,
--     ['vivec, tervur braven: trader'] = true,
--     ['vivec, the abbey of st. delyn the wise'] = true,
--     ['vivec, the flowers of gold'] = true,
--     ['vivec, the lizard\'s head'] = true,
--     ['vos, dreynos elvul\'s farmhouse'] = true,
--     ['vos, fanisea irano\'s farmhouse'] = true,
--     ['vos, ienasa radas\'s farmhouse'] = true,
--     ['vos, maela kaushad\'s farmhouse'] = true,
--     ['vos, mandyn ralas\'s farmhouse'] = true,
--     ['vos, menus felas\'s farmhouse'] = true,
--     ['vos, runethyne andas\'s farmhouse'] = true,
--     ['vos, thilse aralas\'s farmhouse'] = true,
--     ['vos, trilam drolnor\'s farmhouse'] = true,
--     ['vos, ulvil llothas\'s farmhouse'] = true,
--     ['vos, vos chapel'] = true,
-- }

---@type string[]
local tombTiles = {
    'ab_ex_deruin',
    'dr_dung',
    'in_velothilarge_',
    'in_velothismall_',
    'in_v_s_',
    'in_v_l_',
    't_ayl_dngruin',
    't_bre_dngruin',
    't_de_dngrtrongh',
    't_he_dngdirenni',
    't_imp_dngcolbarrow',
    't_imp_dngcrypt',
    't_imp_dngruin',
}

---@type ValidPlaylistCallback
local function tombCellRule()
    return not Playback.state.cellIsExterior
        and Playback.rules.staticMatch(tombTiles)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/interior/barrow',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = barrowCaveTilesRule,
    },
    {
        id = 'ms/interior/dwemer',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = dwemerCellRule,
    },
    {
        id = 'ms/interior/daedric',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = daedricCellRule,
    },
    {
        id = 'ms/interior/ice cave',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = iceCaveTilesRule,
    },
    {
        id = 'ms/interior/sewer',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = sewerCellRule,
    },
    {
        id = 'ms/interior/tomb',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = tombCellRule,
    },
}
