---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type CellMatchPatterns
local eggMineMatches = {
    allowed = {
        "mine",
        "eggmine",
    },
    disallowed = {},
}

--- Works for all trader types instead of specific cell names, but uses a higher priority level
--- So that more specific playlists will actually match instead
---@type ServicesOffered
local traderTypes = {
    Apparatus = true,
    Armor = true,
    Barter = true,
    Books = true,
    Clothing = true,
    Enchanting = true,
    Ingredients = true,
    Lights = true,
    Misc = true,
    MagicItems = true,
    Repair = true,
    RepairItem = true,
    Spellmaking = true,
    Spells = true,
    Training = true,
    Travel = true,
    Picks = true,
    Potions = true,
    Probes = true,
    Weapon = true,
}

---@type CellMatchPatterns
local templePatterns = {
    allowed = { 'temple' },
    disallowed = {},
}

---@type CellMatchPatterns
local campPatterns = {
    allowed = { 'camp' },
    disallowed = {},
}

---@type CellMatchPatterns
local magesPatterns = {
    allowed = { 'mages' },
    disallowed = {},
}

---@type CellMatchPatterns
local ghostgatePatterns = {
    allowed = { 'ghostgate' },
    disallowed = {},
}

---@type ServicesOffered
local smithServices = {
    Armor = true,
    Repair = true,
    RepairItem = true,
}

---@type CellMatchPatterns
local ebonPatterns = {
    allowed = { 'ebonheart' },
    disallowed = {},
}

---@type CellMatchPatterns
local fightersPatterns = {
    allowed = { 'fighters' },
    disallowed = {},
}

---@type CellMatchPatterns
local tongPatterns = {
    allowed = { 'morag tong' },
    disallowed = {},
}

---@type CellMatchPatterns
local pelagiadPatterns = {
    allowed = { 'pelagiad' },
    disallowed = {},
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/mines',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function()
            return Playback.rules.cellNameMatch(eggMineMatches)
        end,
    },
    {
        id = 'ms/cell/traders',
        --- Uses a higher priority level than normal so that anything else using MerchantType which
        --- matches will natively override
        priority = PlaylistPriority.MerchantType + 1,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.localMerchantType(traderTypes)
        end,
    },
    {
        id = 'ms/cell/temples',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.cellNameMatch(templePatterns)
        end,
    },
    {
        id = 'ms/cell/camps',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.cellNameMatch(campPatterns)
        end,
    },
    {
        id = 'ms/cell/mages',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.cellNameMatch(magesPatterns)
        end
    },
    {
        id = 'ms/cell/ghostgate',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.cellNameMatch(ghostgatePatterns)
        end,
    },
    {
        id = 'ms/cell/smiths',
        priority = PlaylistPriority.MerchantType,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.localMerchantType(smithServices)
        end
    },
    {
        id = 'ms/cell/ebonheart',
        priority = PlaylistPriority.MerchantType,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.cellNameMatch(ebonPatterns)
        end,
    },
    {
        id = 'ms/cell/fighters',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.cellNameMatch(fightersPatterns)
        end
    },
    {
        id = 'ms/cell/morag tong',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.cellNameMatch(tongPatterns)
        end,
    },
    {
        id = 'ms/cell/pelagiad',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.cellNameMatch(pelagiadPatterns)
        end
    }
}
