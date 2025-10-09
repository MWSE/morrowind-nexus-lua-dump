---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type CellMatchPatterns
local AshlandersCellMatches = {
    allowed = {
        'ahemmusa camp',
        'ammardunibi camp',
        'baan banif',
        'erabenimsun camp',
        'kaushtababi camp',
        'mamshar-disamus camp',
        'shashurari camp',
        'zainab camp',
    },
    disallowed = {},
}

---@type ValidPlaylistCallback
local function ashlandersCellRule()
    return Playback.rules.cellNameMatch(AshlandersCellMatches)
end

---@type IDPresenceMap
local CaveCellNames = {
    ['abaesen-pulu egg mine'] = true,
    ['abanabi'] = true,
    ['abernanit'] = true,
    ['abinabi'] = true,
    ['adanumuran'] = true,
    ['addamasartus'] = true,
    ['aharnabi'] = true,
    ['aharunartus'] = true,
    ['ahinipalit'] = true,
    ['ainab, shrine'] = true,
    ['ainab'] = true,
    ['ainat'] = true,
    ['akimaes grotto'] = true,
    ['akulakhan\'s chamber'] = true,
    ['ansi'] = true,
    ['arkngthand, deep ore passage'] = true,
    ['arkngthand, hall of centrifuge'] = true,
    ['arkngthand, heaven\'s gallery'] = true,
    ['ashalmawia, shrine, sunken vaults'] = true,
    ['ashalmimilkala, shrine'] = true,
    ['ashanammu'] = true,
    ['ashinabi, smuggler den'] = true,
    ['ashinabi'] = true,
    ['ashirbadon'] = true,
    ['ashir-dan'] = true,
    ['ashurnibibi, shrine'] = true,
    ['assarnud'] = true,
    ['assemanu, shrine'] = true,
    ['assemanu'] = true,
    ['assumanu'] = true,
    ['bal ur, underground'] = true,
    ['bamz-amschend, hearthfire hall'] = true,
    ['bamz-amschend, passage of the walker'] = true,
    ['bensamsi'] = true,
    ['beran ancestral tomb'] = true,
    ['berandas, underground'] = true,
    ['beshara'] = true,
    ['corprusarium bowels'] = true,
    ['corprusarium'] = true,
    ['dagoth ur, facility cavern'] = true,
    ['dagoth ur, lower facility'] = true,
    ['dubdilla'] = true,
    ['dubdilla, uncharted caverns, lower'] = true,
    ['dubdilla, uncharted caverns'] = true,
    ['dun-ahhe'] = true,
    ['dunirai caverns'] = true,
    ['ebonheart, underground caves'] = true,
    ['eluba-addon grotto'] = true,
    ['forgotten vaults of anudnabia, forge of hilbongard'] = true,
    ['gnisis, bethamez'] = true,
    ['gnisis, underground stream'] = true,
    ['habinbaes'] = true,
    ['hassour, shrine'] = true,
    ['hassour'] = true,
    ['hinnabi'] = true,
    ['hla oad, fatleg\'s drop off'] = true,
    ['ibar-dad'] = true,
    ['ilanipu grotto'] = true,
    ['ilunibi, blackened heart'] = true,
    ['ilunibi, carcass of the saint'] = true,
    ['ilunibi, marowak\'s spine'] = true,
    ['ilunibi, soul\'s rattle'] = true,
    ['ilunibi, tainted marrow'] = true,
    ['indoranyon'] = true,
    ['kaushtarari, shrine'] = true,
    ['koal cave'] = true,
    ['kogoruhn, bleeding heart'] = true,
    ['kogoruhn, charma\'s breath'] = true,
    ['kogoruhn, nabith waterway'] = true,
    ['kora-dur'] = true,
    ['kudanat'] = true,
    ['kumarahaz'] = true,
    ['kunirai'] = true,
    ['kushtashpi, shrine'] = true,
    ['maba-ilu'] = true,
    ['madas grotto'] = true,
    ['maelkashishi, shrine, forgotten galleries'] = true,
    ['mallapi'] = true,
    ['malmus grotto'] = true,
    ['mamaea, sanctum of awakening'] = true,
    ['mamaea, sanctum of black hope'] = true,
    ['mamaea, shrine of pitted dreams'] = true,
    ['mannammu'] = true,
    ['maran-adon'] = true,
    ['massama cave'] = true,
    ['masseranit'] = true,
    ['mausur caverns'] = true,
    ['milk'] = true,
    ['minabi, bandit lair'] = true,
    ['minabi'] = true,
    ['ministry of truth, hall of processing'] = true,
    ['ministry of truth, holding cells'] = true,
    ['ministry of truth, prison keep'] = true,
    ['missamsi'] = true,
    ['mount kand, cavern'] = true,
    ['mudan grotto'] = true,
    ['mul grotto'] = true,
    ['nallit'] = true,
    ['nammu'] = true,
    ['nimawia grotto'] = true,
    ['nissintu'] = true,
    ['norenen-dur, basilica of divine whispers'] = true,
    ['norenen-dur, citadel of myn dhrur'] = true,
    ['norenen-dur, the grand stair'] = true,
    ['norenen-dur, the teeth that gnash'] = true,
    ['norenen-dur, the wailingdelve'] = true,
    ['nund'] = true,
    ['odaishah'] = true,
    ['odibaal'] = true,
    ['odirnamat'] = true,
    ['old mournhold: abandoned crypt'] = true,
    ['old mournhold: abandoned passageway'] = true,
    ['old mournhold: armory ruins'] = true,
    ['old mournhold: battlefield'] = true,
    ['old mournhold: bazaar sewers'] = true,
    ['old mournhold: city gate'] = true,
    ['old mournhold: gedna relvel\'s tomb'] = true,
    ['old mournhold: manor district'] = true,
    ['old mournhold: moril manor, courtyard'] = true,
    ['old mournhold: palace sewers'] = true,
    ['old mournhold: residential ruins'] = true,
    ['old mournhold: tears of amun-shae'] = true,
    ['old mournhold: temple catacombs'] = true,
    ['old mournhold: temple crypt'] = true,
    ['old mournhold: temple gardens'] = true,
    ['old mournhold: temple sewers east'] = true,
    ['old mournhold: temple sewers west'] = true,
    ['old mournhold: temple shrine'] = true,
    ['old mournhold: teran hall, east bldg'] = true,
    ['old mournhold: teran hall'] = true,
    ['old mournhold: west sewers'] = true,
    ['omaren ancestral tomb'] = true,
    ['palansour'] = true,
    ['panabanit-nimawia egg mine'] = true,
    ['panat'] = true,
    ['panud egg mine'] = true,
    ['pinsun'] = true,
    ['piran'] = true,
    ['pudai egg mine, queen\'s lair'] = true,
    ['pudai egg mine'] = true,
    ['pulk'] = true,
    ['punabi'] = true,
    ['punammu'] = true,
    ['punsabanit'] = true,
    ['raven rock, abandoned mine shaft'] = true,
    ['raven rock, mine'] = true,
    ['rissun'] = true,
    ['sadrith mora, nevrila areloth\'s house'] = true,
    ['sadrith mora, telvanni council house, hermitage'] = true,
    ['salmantu, shrine'] = true,
    ['salmantu'] = true,
    ['sanabi'] = true,
    ['sanit, shrine'] = true,
    ['sanit'] = true,
    ['sargon'] = true,
    ['sarimisun-assa egg mine, queen\'s lair'] = true,
    ['sarimisun-assa egg mine'] = true,
    ['saturan'] = true,
    ['sennananit'] = true,
    ['setus egg mine'] = true,
    ['sha-adnius'] = true,
    ['shallit'] = true,
    ['shal'] = true,
    ['sharapli'] = true,
    ['shulk egg mine, mining camp'] = true,
    ['shulk egg mine, queen\'s lair'] = true,
    ['shulk egg mine'] = true,
    ['shurdan-raplay egg mine'] = true,
    ['shurinbaal'] = true,
    ['shushan'] = true,
    ['shushishi'] = true,
    ['sinamusa egg mine'] = true,
    ['sinarralit egg mine'] = true,
    ['sinsibadon'] = true,
    ['subdun, shrine'] = true,
    ['subdun'] = true,
    ['sudanit mine'] = true,
    ['sur egg mine'] = true,
    ['surirulk'] = true,
    ['telasero, upper level'] = true,
    ['tel branora, tower dungeon'] = true,
    ['tel uvirith, tower dungeon'] = true,
    ['tel vos, dungeon'] = true,
    ['tel vos, jail'] = true,
    ['tin-ahhe'] = true,
    ['tukushapal, sepulcher'] = true,
    ['tukushapal'] = true,
    ['ularradallaku, shrine'] = true,
    ['ulummusa'] = true,
    ['urshilaku, astral burial'] = true,
    ['urshilaku, fragile burial'] = true,
    ['urshilaku, juno burial'] = true,
    ['urshilaku, kakuna burial'] = true,
    ['urshilaku, karma burial'] = true,
    ['urshilaku, kefka burial'] = true,
    ['urshilaku, laterus burial'] = true,
    ['vansunalit egg mine'] = true,
    ['vassamsi grotto'] = true,
    ['vassir-didanat cave'] = true,
    ['vivec, hlaalu underworks'] = true,
    ['vivec, st. delyn underworks'] = true,
    ['yakanalit'] = true,
    ['yakin, shrine'] = true,
    ['yanemus mine'] = true,
    ['yansirramus, shrine'] = true,
    ['yasamsi'] = true,
    ['yassu mine'] = true,
    ['yesamsi'] = true,
    ['zainsipilu'] = true,
    ['zaintirari'] = true,
    ['zalkin grotto'] = true,
    ['zalkin-sul egg mine'] = true,
    ['zanabi'] = true,
    ['zebabi'] = true,
    ['zenarbael'] = true,
}

---@type string[]
local caveMatches = {
    'ab_in_kwama',
    'ab_in_lava',
    'ab_in_mvcave',
    'ab_in_cave',
    'ab_in_mine',
    'i_lavarock',
    'i_moldrock',
    'i_mudrock',
}

---@type ValidPlaylistCallback
local function caveCellRule()
    return not Playback.state.cellIsExterior
        and (
            Playback.rules.cellNameExact(CaveCellNames)
            or Playback.rules.staticExact(Tilesets.Cave)
            or Playback.rules.staticMatch(caveMatches)
        )
end

---@type CellMatchPatterns
local ClockworkcityCellMatches = {
    allowed = {
        'sotha sil',
    },
    disallowed = {},
}

---@type ValidPlaylistCallback
local function clockworkCityRule()
    return Playback.rules.cellNameMatch(ClockworkcityCellMatches)
end

---@type IDPresenceMap
local corprusariumCells = {
    ['corprusarium'] = true,
    ['corprusarium bowels'] = true,
}

---@type ValidPlaylistCallback
local function corprusariumCellRule()
    return Playback.rules.cellNameExact(corprusariumCells)
end

---@type CellMatchPatterns
local strongholdMatches = {
    allowed = {
        'andasreth',
        'berandas',
        'falensarano',
        'hlormaren',
        'indoranyon',
        'marandus',
        'rotheran',
        'valenvaryon',
        'falasmaryon, propylon chamber',
        'telasero, propylon chamber',
    },
    disallowed = {
        'kogoruhn',
        'sewers',
    },
}

---@type ValidPlaylistCallback
local function strongholdsRule()
    return Playback.rules.cellNameMatch(strongholdMatches)
end

---@type IDPresenceMap
local firemothCellNames = {
    ['firemoth, keep'] = true,
    ['firemoth, great hall'] = true,
    ['firemoth, upper chambers'] = true,
    ['firemoth, guard quarters'] = true,
    ['firemoth, dungeon'] = true,
    ['firemoth, lower cavern'] = true,
    ['firemoth, tomb'] = true,
    ['firemoth, guard towers'] = true,
    ['firemoth, upper cavern'] = true,
    ['firemoth, mine'] = true,
}

---@type ValidPlaylistCallback
local function firemothCellRule()
    return Playback.state.nearestRegion == 'firemoth region'
        or Playback.rules.cellNameExact(firemothCellNames)
end

---@type CellMatchPatterns
local grottoMatches = {
    allowed = {
        'grotto',
        'shipwreck',
        'wrecked slave ship',
    },
    disallowed = {},
}

---@type ValidPlaylistCallback
local function grottosRule()
    return Playback.rules.cellNameMatch(grottoMatches)
end

---@type CellMatchPatterns
local HlaaluCellMatches = {
    allowed = {
        'arvel plantation',
        'balmora',
        'bo-muul',
        'dren plantation',
        'fatleg\'s camp',
        'gnaar mok',
        'hla oad',
        'stendarr\'s retreat',
        'suran',
        'vivec, curio manor',
        'vivec, hlaalu ',
        'vivec, no name club',
    },
    disallowed = {
        'balmora, temple',
        'balmora, eight plates',
        'balmora, south wall cornerclub',
        'balmora, lucky lockup',
        'sewers',
        'suran, suran temple',
        'suran, desele\'s house of earthly delights',
        'underworks',
        'vivec, elven nations cornerclub',
        'vivec, hlaalu temple'
    },
}

---@type ValidPlaylistCallback
local function hlaaluCellRule()
    return Playback.rules.cellNameMatch(HlaaluCellMatches)
end

---@type CellMatchPatterns
local ImperialCellMatches = {
    allowed = {
        'caldera',
        'ebonheart',
        'fort',
        'gnisis',
        'pelagiad',
        'seyda neen, census and excise office',
        'seyda neen, census and excise warehouse',
        'wolverine hall',
    },
    disallowed = {
        'ebonheart, six fishes',
        'ebonheart, imperial chapels',
        'eggmine',
        'fort firemoth',
        'fort frostmoth',
        'gnisis, temple',
        'gnisis, cavern tavern',
        'mine',
        'pelagiad, halfway tavern',
        'sewers',
        'underworks',
    },
}

---@type ValidPlaylistCallback
local function imperialCellRule()
    return Playback.rules.cellNameMatch(ImperialCellMatches)
end

---@type CellMatchPatterns
local mineMatches = {
    allowed = {
        'mine',
        'eggmine',
        'egg mine',
        'mausur caverns',
        'vassir-didanat cave',
        'dunirai caverns',
        'massama cave',
    },
    disallowed = {},
}

---@type ValidPlaylistCallback
local function minesRule()
    return Playback.rules.cellNameMatch(mineMatches)
end

---@type CellMatchPatterns
local mournholdMatches = {
    allowed = {
        'mournhold,',
    },
    disallowed = {
        'sewers',
        'underworks',
        'old mournhold',
        'mournhold temple',
    }
}

---@type IDPresenceMap
local disallowedMournholdCells = {
    ['Mournhold, Plaza Brindisi Dorom'] = true,
    ['Mournhold, The Winged Guar'] = true,
    ['Mournhold, Temple Courtyard'] = true,
}

---@type ValidPlaylistCallback
local function mournholdCellRule()
    return not Playback.rules.cellNameExact(disallowedMournholdCells)
        and Playback.rules.cellNameMatch(mournholdMatches)
end

---@type CellMatchPatterns
local nordicMatches = {
    allowed = {
        'ald redaynia',
        'dagon fel',
        'raven rock',
        'sheogorad, odmlir wulfharth\'s house',
        'sheogorad, the wulfharth abode',
        'skaal village',
        'solstheim, graring\'s house',
        'solstheim, uncle sweetshare\'s workshop',
    },
    disallowed = {
        'ald redaynia, tower',
        'dagon fel, the end of the world',
        'raven rock, bar',
        'skaal village, the greathall',
    },
}

---@type ValidPlaylistCallback
local function nordicCellRule()
    return Playback.rules.cellNameMatch(nordicMatches)
end

---@type IDPresenceMap
local oldMournholdCells = {
    ["old mournhold: abandoned crypt"] = true,
    ["old mournhold: abandoned passageway"] = true,
    ["old mournhold: armory ruins"] = true,
    ["old mournhold: battlefield"] = true,
    ["old mournhold: city gate"] = true,
    ["old mournhold: gedna relvel's tomb"] = true,
    ["old mournhold: manor district"] = true,
    ["old mournhold: moril manor, courtyard"] = true,
    ["old mournhold: moril manor, east building"] = true,
    ["old mournhold: moril manor, north building"] = true,
    ["old mournhold: residential ruins"] = true,
    ["old mournhold: tears of amun-shae"] = true,
    ["old mournhold: temple catacombs"] = true,
    ["old mournhold: temple crypt"] = true,
    ["old mournhold: temple gardens"] = true,
    ["old mournhold: temple shrine"] = true,
    ["old mournhold: teran hall, east bldg"] = true,
    ["old mournhold: teran hall"] = true,
}

---@type ValidPlaylistCallback
local function oldMournholdRule()
    return Playback.rules.cellNameExact(oldMournholdCells)
end

---@type CellMatchPatterns
local redoranCellMatches = {
    allowed = {
        'ald velothi',
        'ghostgate, tower of dusk',
        'indarys manor',
        'khuul',
        'maar gan',
        'morvayn manor',
        'ruhn',
        'st rilms beacon',
        'vivec, dralor manor',
        'vivec, redoran ',
        'vivec, saren manor',
        'vivec, the flowers of gold',
    },
    disallowed = {
        'ald-ruhn, council club',
        'ald-ruhn, temple',
        'eggmine',
        'gnisis',
        'khuul, thongar\'s tradehouse',
        'kogoruhn',
        'maar gan, shrine',
        'sewers',
        'tel aruhn',
        'underworks',
        'vivec, redoran temple shrine',
    },
}

---@type ValidPlaylistCallback
local function redoranCellRule()
    return Playback.rules.cellNameMatch(redoranCellMatches)
end

---@type IDPresenceMap`
local oldMournholdSewers = {
    ['old mournhold: bazaar sewers'] = true,
    ['old mournhold: forgotten sewer'] = true,
    ['old mournhold: palace sewers'] = true,
    ['old mournhold: residential sewers'] = true,
    ['old mournhold: temple sewers east'] = true,
    ['old mournhold: temple sewers'] = true,
    ['old mournhold: temple sewers west'] = true,
    ['old mournhold: west sewers'] = true,
}

---@type CellMatchPatterns
local SewersCellMatches = {
    allowed = {
        'sewer',
        'sewers',
        'underworks',
    },
    disallowed = {
        'temple sewers',
    },
}

---@type string[]
local sewerTiles = {
    'ab_in_hlasewer',
    'in_sewer_',
    'in_sewer_canal',
    'in_sewer_pillar',
    'in_sewer_union',
    't_imp_dngsewers',
}

---@type ValidPlaylistCallback
local function sewersCellRule()
    return Playback.rules.cellNameExact(oldMournholdSewers)
        or Playback.rules.cellNameMatch(SewersCellMatches)
        or Playback.rules.staticMatch(sewerTiles)
end

--- These seem like they're probably actually exact matches
---@type CellMatchPatterns
local sixthHouseBaseMatches = {
    allowed = {
        'abanabi',
        'ainab',
        'assemanu',
        'bensamsi',
        'falasmaryon,',
        'hassour',
        'ilunibi',
        'mamaea',
        'maran-adon',
        'missamsi',
        'morvayn manor',
        'piran',
        'rissun',
        'salmantu',
        'sanit',
        'sennananit',
        'sharapli',
        'subdun',
        'telasero,',
        'yakin',
    },
    disallowed = {
        'mussin akin\'s hut',
        'propylon chamber',
        'sewers',
    },
}

---@type ValidPlaylistCallback
local function sixthHouseBaseRule()
    return Playback.rules.cellNameMatch(sixthHouseBaseMatches)
end

---@type CellMatchPatterns
local sixthHouseCitadels = {
    allowed = {
        'akulakhan\'s chamber',
        'dagoth ur',
        'endusal',
        'kogoruhn',
        'odrosal',
        'tureynulal',
        'vemynal',
    },
    disallowed = {
        'propylon chamber',
    },
}

---@type ValidPlaylistCallback
local function sixthHouseCitadelRule()
    return Playback.rules.cellNameMatch(sixthHouseCitadels)
end

---@type CellMatchPatterns
local telvanniCells = {
    allowed = {
        'balmora, telvanni consulate',
        'ebonheart, garos relvani\'s abode',
        'sadrith mora',
        'outer realms, ulaeash',
        'tel aruhn',
        'tel azura',
        'tel branora',
        'tel dwemeris',
        'tel fyr',
        'tel llarelah',
        'tel koj-ruskthss',
        'tel mora',
        'tel vos',
        'tel uvirith',
        'vivec, telvanni ',
        'vivec, hlaren residence',
        'vivec, temporary telvanni housing',
        'vos',
    },
    disallowed = {
        "sadrith mora, gateway inn",
        "sadrith mora, wolverine hall: imperial shrine",
        "sewers",
        "telvanni council house, chambers",
        "underworks",
        "vivec, telvanni temple",
        "vivec, the lizard's head",
        "vos, vos chapel",
        "vos, varo tradehouse",
        "wolverine hall",
    },
}

---@type ValidPlaylistCallback
local function telvanniRule()
    return Playback.rules.cellNameMatch(telvanniCells)
end

---@type CellMatchPatterns
local templeCells = {
    allowed = {
        ['ghostgate'] = true,
        ['ghostgate, tower of dawn lower level'] = true,
        ['ghostgate, tower of dawn'] = true,
        ['koal cave entrance'] = true,
        -- Couldn't source this one
        ['kummu monastery'] = true,
        ['molag mar, armigers stronghold'] = true,
        ['molag mar, canalworks'] = true,
        ['molag mar, redoran stronghold'] = true,
        ['molag mar, saetring the nord: smith'] = true,
        ['molag mar, st. veloth\'s hostel'] = true,
        ['molag mar, the pilgrim\'s rest'] = true,
        ['molag mar'] = true,
        ['molag mar, vasesius viciulus: trader'] = true,
        ['molag mar, waistworks'] = true,
        ['mournhold temple: basement'] = true,
        ['mournhold, temple courtyard'] = true,
        ['mournhold temple: hall of ministry'] = true,
        ['mournhold temple: infirmary'] = true,
        ['mournhold temple: office of the lord archcanon'] = true,
        ['mournhold temple: reception area'] = true,
        ['mournhold temple'] = true,
        ['vivec, canon offices'] = true,
        ['vivec, canon quarters'] = true,
        ['vivec, hall of justice'] = true,
        ['vivec, hall of wisdom'] = true,
        ['vivec, justice offices'] = true,
        ['vivec, milo\'s quarters'] = true,
        ['vivec, office of the watch'] = true,
        ['vivec, ordinator barracks'] = true,
    },
    disallowed = {},
}

---@type ValidPlaylistCallback
local function templeCellRule()
    return Playback.rules.cellNameMatch(templeCells)
end

---@type IDPresenceMap
local vampireBaseCells = {
    ['alen ancestral tomb'] = true,
    ['andrethi ancestral tomb'] = true,
    ['aralen ancestral tomb'] = true,
    ['ashmelech'] = true,
    ['drethan ancestral tomb'] = true,
    ['druscashti'] = true,
    ['dulo ancestral tomb'] = true,
    ['galom daeus'] = true,
    ['hleran ancestral tomb'] = true,
    ['ginith ancestral tomb'] = true,
    ['nerano ancestral tomb'] = true,
    ['othrelas ancestral tomb'] = true,
    ['raviro ancestral tomb'] = true,
    ['reloth ancestral tomb'] = true,
    ['salvel ancestral tomb'] = true,
    ['sarethi ancestral tomb'] = true,
    ['serano ancestral tomb'] = true,
}

---@type ValidPlaylistCallback
local function vampireBasesRule()
    return Playback.rules.cellNameExact(vampireBaseCells)
end

---@type IDPresenceMap
local velothiTowerCells = {
    ['ald redaynia, tower'] = true,
    -- ???
    ['arvs-drelen'] = true,
    ["gnisis, arvs-drelen"] = true,
    ['hanud'] = true,
    ["hanud, tower"] = true,
    ['mababi'] = true,
    ['mawia'] = true,
    ['odirniran'] = true,
    ["odirniran, tower"] = true,
    ['sanni'] = true,
    ['shara'] = true,
    ['shishi'] = true,
    ['sulipund'] = true,
    ['vas'] = true,
    ["vas, tower"] = true,
}

---@type ValidPlaylistCallback
local function velothiTowersRule()
    return Playback.rules.cellNameExact(velothiTowerCells)
end

---@type CellMatchPatterns
local vivecMatches = {
    allowed = {
        'vivec',
    },
    disallowed = {
        'sewers',
        'underworks',
        'puzzle canal',
        'vivec, canon',
        'vivec, hlaalu ',
        'vivec, milo\'s quarters',
        'vivec, palace ',
        'vivec, redoran ',
        'vivec, telvanni ',
    },
}

---@type ValidPlaylistCallback
local function vivecRule()
    return Playback.rules.cellNameMatch(vivecMatches)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/public/ashlanders',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = ashlandersCellRule,
    },
    {
        id = 'ms/interior/cave',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = caveCellRule,
    },
    {
        id = 'ms/cell/dungeon/clockwork city',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = clockworkCityRule,
    },
    {
        id = 'ms/cell/dungeon/corprusarium',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = corprusariumCellRule,
    },
    {
        id = 'ms/cell/dungeon/dunmer strongholds',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = strongholdsRule,
    },
    {
        id = 'ms/cell/dungeon/fort firemoth',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = firemothCellRule,
    },
    {
        id = 'ms/cell/dungeon/grottos',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = grottosRule,
    },
    {
        id = 'ms/cell/public/hlaalu',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = hlaaluCellRule,
    },
    {
        id = 'ms/cell/public/imperial',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = imperialCellRule,
    },
    {
        id = 'ms/cell/dungeon/mines',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = minesRule,
    },
    {
        id = 'ms/cell/public/mournhold',
        priority = PlaylistPriority.City,
        randomize = true,

        isValidCallback = mournholdCellRule,
    },
    {
        id = 'ms/cell/public/nordic',
        priority = PlaylistPriority.City,
        randomize = true,

        isValidCallback = nordicCellRule,
    },
    {
        id = 'ms/cell/dungeon/old mournhold, ruins',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = oldMournholdRule,
    },
    {
        id = 'ms/cell/public/redoran',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = redoranCellRule,
    },
    {
        id = 'ms/interior/sewer',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = sewersCellRule,
    },
    {
        id = 'ms/cell/dungeon/sixth house bases',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = sixthHouseBaseRule,
    },
    {
        id = 'ms/cell/dungeon/sixth house citadels',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = sixthHouseCitadelRule,
    },
    {
        id = 'ms/cell/public/telvanni',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = telvanniRule,
    },
    {
        id = 'ms/cell/public/temple',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = templeCellRule,
    },
    {
        id = 'ms/cell/dungeon/vampire bases',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = vampireBasesRule,
    },
    {
        id = 'ms/cell/dungeon/velothi towers',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = velothiTowersRule,
    },
    {
        id = 'ms/cell/public/vivec',
        priority = PlaylistPriority.City,
        randomize = true,

        isValidCallback = vivecRule,
    },
}
