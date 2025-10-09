---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type ValidPlaylistCallback
local function highFaneRule()
    return Playback.state.cellName == 'vivec, high fane'
end

---@type IDPresenceMap
local vivecLibraryCells = {
    ["vivec, library of vivec"] = true,
    ["vivec, hall of justice secret library"] = true,
}

---@type ValidPlaylistCallback
local function vivecLibraryRule()
    return Playback.rules.cellNameExact(vivecLibraryCells)
end

---@type IDPresenceMap
local ministryOfTruthCells = {
    ["ministry of truth, hall of processing"] = true,
    ["ministry of truth, holding cells"] = true,
    ["ministry of truth, prison keep"] = true,
}

---@type ValidPlaylistCallback
local function ministryOfTruthRule()
    return Playback.rules.cellNameExact(ministryOfTruthCells)
end

---@type ValidPlaylistCallback
local function vivecpalaceCellRule()
    return Playback.state.cellName == 'vivec, palace of vivec'
end

---@type ValidPlaylistCallback
local function puzzleCanalRule()
    return Playback.state.cellName == 'vivec, puzzle canal, center'
end

---@type IDPresenceMap
local tribunalTempleCells = {
    ['ald-ruhn, temple'] = true,
    ['balmora, temple'] = true,
    ['gnisis, temple'] = true,
    ['maar gan, shrine'] = true,
    ['molag mar, temple'] = true,
    ['mournhold temple: high chapel'] = true,
    ['suran, suran temple'] = true,
    ['vivec, hlaalu temple'] = true,
    ['vivec, redoran temple shrine'] = true,
    ['vivec, st. olms temple'] = true,
    ['vivec, telvanni temple'] = true,
    ['vivec, the abbey of st. delyn the wise'] = true,
    ['vos, vos chapel'] = true,
    ['telvanni council house, chambers'] = true,
}

---@type ValidPlaylistCallback
local function tribunalTempleRule()
    return Playback.rules.cellNameExact(tribunalTempleCells)
end

---@type IDPresenceMap
local urshilakuMatches = {
    ["urshilaku camp"] = true,
    ["urshilaku camp, ahasour's yurt"] = true,
    ["urshilaku camp, ashkhan's yurt"] = true,
    ["urshilaku camp, kurapli's yurt"] = true,
    ["urshilaku camp, maeli's yurt"] = true,
    ["urshilaku camp, sakiran's yurt"] = true,
    ["urshilaku camp, shara's yurt"] = true,
    ["urshilaku camp, shimsun's yurt"] = true,
    ["urshilaku camp, wise woman's yurt"] = true,
    ["urshilaku camp, zabamund's yurt"] = true,
    ["urshilaku camp, zanummu's yurt"] = true,
}

---@type ValidPlaylistCallback
local function urshilakuRule()
    return Playback.rules.cellNameExact(urshilakuMatches)
end

---@type IDPresenceMap
local azuraShrine = {
    ['shrine of azura'] = true,
}

---@type ValidPlaylistCallback
local function shrineofazuraCellRule()
    return Playback.rules.cellNameExact(azuraShrine)
end

---@type IDPresenceMap
local mephalaShrine = {
    ['vivec, arena hidden area'] = true,
}

---@type ValidPlaylistCallback
local function mephalaShrineRule()
    return Playback.rules.cellNameExact(mephalaShrine)
end

---@type IDPresenceMap
local sheoShrine = {
    ['ihinipalit, shrine'] = true,
}

---@type ValidPlaylistCallback
local function sheoShrineRule()
    return Playback.rules.cellNameExact(sheoShrine)
end

---@type IDPresenceMap
local mournholdCells = {
    ["mournhold, plaza brindisi dorom"] = true,
}

---@type ValidPlaylistCallback
local function mournholdPlazaRule()
    return Playback.rules.cellNameExact(mournholdCells)
end

---@type IDPresenceMap
local imperialShrineCells = {
    ["ebonheart, imperial chapels"] = true,
    ["fort frostmoth, imperial cult shrine"] = true,
    ["mournhold, royal palace: imperial cult services"] = true,
    ["sadrith mora, wolverine hall: imperial shrine"] = true,
}

---@type CellMatchPatterns
local shrineMatches = {
    allowed = {
        'imperial shrine',
        'imperial cult',
    },
    disallowed = {},
}

---@type ValidPlaylistCallback
local function imperialShrineRule()
    return Playback.rules.cellNameExact(imperialShrineCells)
        or Playback.rules.cellNameMatch(shrineMatches)
end

---@type CellMatchPatterns
local MeadhallMatches = {
    allowed = {
        'dagon fel, the end of the world',
        'raven rock, bar',
        'skaal village, the greathall',
        'solstheim, thirsk',
    },
    disallowed = {},
}

---@type ValidPlaylistCallback
local function meadhallRule()
    return Playback.rules.cellNameMatch(MeadhallMatches)
end

---@type IDPresenceMap
local hlaaluManorCells = {
    ["arvel manor"] = true,
    ["arvel manor, slavemaster's shack"] = true,
    ["arvel manor, slave shack"] = true,
    ["arvel manor, storage shack"] = true,
    ["omani manor"] = true,
    ["rethan manor"] = true,
    ["rethan manor, berendas' house"] = true,
    ["rethan manor, drelas' house"] = true,
    ["rethan manor, gols' house"] = true,
    ["rethan manor, tures' house"] = true,
    ["ules manor"] = true,
    ["ules manor, slavemaster's shack"] = true,
    ["ules manor, slave shack"] = true,
    ["vivec, st. olms yngling manor basement"] = true,
    ["vivec, st. olms yngling manor"] = true,
}

---@type ValidPlaylistCallback
local function hlaaluManorRule()
    return Playback.rules.cellNameExact(hlaaluManorCells)
end

---@type IDPresenceMap
local holamayanCells = {
    ['holamayan'] = true,
    ['holamayan monastery'] = true,
}

---@type ValidPlaylistCallback
local function holamayanCellRule()
    return Playback.rules.cellNameExact(holamayanCells)
end

---@type IDPresenceMap
local earthlyDelightsCells = {
    ["suran, desele's house of earthly delights"] = true,
}

---@type ValidPlaylistCallback
local function houseofearthlydelightsCellRule()
    return Playback.rules.cellNameExact(earthlyDelightsCells)
end

---@type IDPresenceMap
local frostmothCells = {
    ['fort frostmoth'] = true,
    ['fort frostmoth, armory'] = true,
    ['fort frostmoth, carius\' chambers'] = true,
    ['fort frostmoth, curtain wall'] = true,
    ['fort frostmoth, general quarters'] = true,
    ['fort frostmoth, general quarters, upper level'] = true,
    --- Should the other imperial temple playlist override this or not?
    ['fort frostmoth, imperial cult shrine'] = true,
    ['fort frostmoth, lighthouse'] = true,
    ['fort frostmoth, prison'] = true,
    ['fort frostmoth, storage tower'] = true,
    ['fort frostmoth, supply room'] = true,
    ['solstheim, lokken castle'] = true,
}

---@type ValidPlaylistCallback
local function frostmothRule()
    return Playback.rules.cellNameExact(frostmothCells)
end

---@type IDPresenceMap
local ghostgateCells = {
    ['ghostfence'] = true,
    ['ghostgate'] = true,
    ['ghostgate, temple'] = true,
    ['ghostgate, tower of dawn lower level'] = true,
    ['ghostgate, tower of dawn'] = true,
    ['ghostgate, tower of dusk lower level'] = true,
    ['ghostgate, tower of dusk'] = true,
}

---@type S3maphoreCellGrid[]
local ghostgateGrids = {
    { x = 2, y = 5 },
}

---@type ValidPlaylistCallback
local function ghostgateRule()
    return Playback.rules.exteriorGrid(ghostgateGrids)
        or Playback.rules.cellNameExact(ghostgateCells)
end

---@type ValidPlaylistCallback
local function incarnateCellRule()
    return Playback.state.cellName == 'cavern of the incarnate'
end

---@type S3maphorePlaylistEnv
return {
    {
        id = 'ms/cell/special/cavern of the incarnate',
        priority = PlaylistPriority.CellExact - 2,
        randomize = true,

        isValidCallback = incarnateCellRule,
    },
    {
        id = 'ms/cell/special/fort frostmoth',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = frostmothRule,
    },
    {
        id = 'ms/cell/special/ghostgate temple',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = ghostgateRule,
    },
    {
        id = 'ms/cell/special/hlaalu manors',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = hlaaluManorRule,
    },
    {
        id = 'ms/cell/special/holamayan',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = holamayanCellRule,
    },
    {
        id = 'ms/cell/special/house of earthly delights',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = houseofearthlydelightsCellRule,
    },
    {
        id = 'ms/cell/special/imperial prison ship',
        priority = PlaylistPriority.Special,
        randomize = true,

        isValidCallback = function()
            return Playback.state.cellName == 'imperial prison ship'
        end,
    },
    {
        id = 'ms/cell/special/mead hall',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = meadhallRule,
    },
    {
        id = 'ms/cell/special/mournhold plaza',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = mournholdPlazaRule,
    },
    {
        id = 'ms/cell/special/shrine of azura',
        priority = PlaylistPriority.CellExact - 1,
        randomize = true,

        isValidCallback = shrineofazuraCellRule,
    },
    {
        id = 'ms/cell/special/shrine of mephala',
        priority = PlaylistPriority.CellExact - 1,
        randomize = true,

        isValidCallback = mephalaShrineRule,
    },
    {
        id = 'ms/cell/special/shrine of sheogorath',
        priority = PlaylistPriority.CellExact - 1,
        randomize = true,

        isValidCallback = sheoShrineRule,
    },
    {
        id = 'ms/cell/special/tribunal temples',
        priority = PlaylistPriority.CellExact - 1,
        randomize = true,

        isValidCallback = tribunalTempleRule,
    },
    {
        id = 'ms/cell/special/urshilaku camp',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = urshilakuRule,
    },
    {
        id = 'ms/cell/special/vivec, high fane',
        priority = PlaylistPriority.CellExact - 1,
        randomize = true,

        isValidCallback = highFaneRule,
    },
    {
        id = 'ms/cell/special/vivec, library',
        priority = PlaylistPriority.CellExact - 1,
        randomize = true,

        isValidCallback = vivecLibraryRule,
    },
    {
        id = 'ms/cell/special/vivec, ministry of truth',
        priority = PlaylistPriority.CellExact - 1,
        randomize = true,

        isValidCallback = ministryOfTruthRule,
    },
    {
        id = 'ms/cell/special/vivec, palace',
        priority = PlaylistPriority.CellExact - 1,
        randomize = true,

        isValidCallback = vivecpalaceCellRule,
    },
    {
        id = 'ms/cell/special/vivec, puzzle canal',
        priority = PlaylistPriority.CellExact - 1,
        randomize = true,

        isValidCallback = puzzleCanalRule,
    },
    {
        id = 'ms/cell/special/imperial chapel',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = imperialShrineRule,
    },
}
