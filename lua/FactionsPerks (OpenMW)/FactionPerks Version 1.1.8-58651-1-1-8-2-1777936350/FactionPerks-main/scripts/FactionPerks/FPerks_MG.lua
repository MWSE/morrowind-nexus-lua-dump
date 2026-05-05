--[[
    MG:
        FPerks_MG1_Passive          - +3 Intelligence, +3 Endurance,
                                      +10 Fortify Magicka, +5 Destruction, +5 Alteration
        FPerks_MG2_Passive          - +5 Intelligence, +5 Endurance,
                                      +20 Fortify Magicka, +10 Destruction, +10 Alteration
        FPerks_MG3_Passive          - +10 Intelligence, +10 Endurance,
                                      +35 Fortify Magicka, +18 Destruction, +18 Alteration,
                                      Fortify Maximum Magicka 0.5x Intelligence (magnitude 5)
        FPerks_MG4_Passive          - +15 Intelligence, +15 Endurance,
                                      +50 Fortify Magicka, +25 Destruction, +25 Alteration,
                                      Fortify Maximum Magicka 1.0x Intelligence (magnitude 10)

    NOTE: Fortify Magicka is applied via stat.modifier so the maximum is raised correctly.
    Fortify Maximum Magicka (MG3/MG4) is a distinct effect and remains in the ESP.

    All character-specific data (visited Places of Power, applied effect values,
    and appliedMagickaMod) is persisted via onSave/onLoad so it is isolated per
    character and per save.

    Magical Cartography (P2+):
        Visiting Places of Power builds two scaling bonuses:
            Per location visited:    +1 Resist Magicka, +2 Detect Enchantment
            Per 10 locations:        +5% magicka refund on successful spell cast (max 25%)

        Console commands (type in the in-game console):
            lua mg cartography dump  - prints all stored Places of Power for this character
            lua mg cartography clear - wipes this character's visited table and resets effects
]]

local ns          = require("scripts.FactionPerks.namespace")
local utils       = require("scripts.FactionPerks.utils")
local perkHidden  = utils.perkHidden
local GUILD        = utils.FACTION_GROUPS.magesGuild
local interfaces  = require("openmw.interfaces")
local types       = require('openmw.types')
local self        = require('openmw.self')
local core        = require('openmw.core')
local ui          = require('openmw.ui')

local R = interfaces.ErnPerkFramework.requirements

local perkTable = {
    [1] = { passive = {"FPerks_MG1_Passive"} },
    [2] = { passive = {"FPerks_MG2_Passive"} },
    [3] = { passive = {"FPerks_MG3_Passive"} },
    [4] = { passive = {"FPerks_MG4_Passive"} },
}

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  CHARACTER-SPECIFIC STATE
--  All of these are saved/loaded via onSave/onLoad.
-- ============================================================

local appliedMagickaMod = 0  -- current value written to stat.modifier
local appliedResist     = 0  -- current Resist Magicka bonus applied
local appliedDetect     = 0  -- current Detect Enchantment bonus applied
local visited           = {} -- map of cellId -> cellName for this character

-- ============================================================
--  FORTIFY MAGICKA - stat.modifier approach
-- ============================================================

local function applyMagickaMod(value)
    local s = types.Actor.stats.dynamic.magicka(self)
    local delta = value - appliedMagickaMod
    s.modifier = s.modifier + delta
    if delta > 0 then
        s.maximum = s.maximum + delta
    end
    appliedMagickaMod = value
end

-- ============================================================
--  MAGICAL CARTOGRAPHY - Scholastic Rigour (P2+)
-- ============================================================

local hasMGCartography = false
local castedSpell      = nil
local lastCastCost     = 0
local lastCellId       = nil
local cellCheckTimer   = 0
local CELL_CHECK_INTERVAL = 2.0

-- ============================================================
--  LOCATION DETECTION
-- ============================================================

local UNIQUE_LOCATIONS = {
    -- Vanilla
    ["akulakhan's chamber"] = true,
    ["vivec, palace of vivec"]     = true,
    ["mournhold temple: high chapel"]         = true,
    ["sotha sil, dome of sotha sil"]   = true,
    ["magas volar"]   = true,
    ["solstheim, mortrag glacier: huntsman's hall"]   = true,
    -- TR
    ["vorthas uldun, chambers of methats uldun"]   = true,
    ["mala tor, lattagarlas"]   = true,
    ["old ebonheart, guild of mages: entrance hall"]   = true,
    ["the space gone missing, outer caverns"]   = true,
    -- PT
    ["garlas agea, aransel"] = true,
    -- SHotN
}

local function isPlaceOfPower(cellName)
    if type(cellName) ~= "string" then return false end
    local lower = cellName:lower()
    if lower:find("inner shrine",     1, true) then return true end
    if lower:find("propylon chamber", 1, true) then return true end
    if UNIQUE_LOCATIONS[lower]                 then return true end
    return false
end

-- ============================================================
--  VISITED COUNT AND REFUND CALCULATION
-- ============================================================

local function getVisitedCount()
    local count = 0
    for _ in pairs(visited) do count = count + 1 end
    return count
end

local function getRefundPercent(count)
    return math.min(math.floor(count / 10) * 0.05, 0.25)
end

-- ============================================================
--  EFFECT APPLICATION
--  Uses delta-based modification so repeated calls (including
--  on load after restoring values from the save) never
--  double-apply the bonus.
-- ============================================================

local function applyCartographyEffects(count)
    local activeEffects = types.Actor.activeEffects(self)

    local targetResist = count
    local targetDetect = count * 2

    local deltaResist = targetResist - appliedResist
    local deltaDetect = targetDetect - appliedDetect

    if deltaResist ~= 0 then
        activeEffects:modify(deltaResist, "resistmagicka")
        appliedResist = targetResist
    end
    if deltaDetect ~= 0 then
        activeEffects:modify(deltaDetect, "detectenchantment")
        appliedDetect = targetDetect
    end
end

local function removeCartographyEffects()
    applyCartographyEffects(0)
end

-- ============================================================
--  CELL DISCOVERY
-- ============================================================

local function checkCurrentCell(currentCell)
    if not currentCell then return end

    local cellName = currentCell.name
    if type(cellName) ~= "string" then return end
    if cellName == "" then return end

    if not isPlaceOfPower(cellName) then return end

    local cellId = currentCell.id
    if visited[cellId] then return end

    local oldCount = getVisitedCount()
    visited[cellId] = cellName
    local newCount = oldCount + 1

    applyCartographyEffects(newCount)

    local oldMilestone = math.floor(oldCount / 10)
    local newMilestone = math.floor(newCount / 10)

    if newMilestone > oldMilestone and newMilestone <= 5 then
        local refundPct = newMilestone * 5
        ui.showMessage("Magical Cartography: " .. newCount
            .. " Places of Power catalogued. Spell refund: "
            .. refundPct .. "%.")
    else
        ui.showMessage("Magical Cartography: Place of Power catalogued. ("
            .. newCount .. " total)")
    end

    print("MG Cartography: Discovered '" .. cellName
        .. "' (total: " .. newCount .. ")")
end

-- ============================================================
--  SPELL CAST TRACKING
-- ============================================================

interfaces.AnimationController.addTextKeyHandler('', function(groupname, key)
    if groupname ~= "spellcast" then return end
    if key == "self start" or key == "touch start" or key == "target start" then
        castedSpell  = types.Player.getSelectedSpell(self)
        lastCastCost = castedSpell and castedSpell.cost or 0
    elseif key == "self stop" or key == "touch stop" or key == "target stop" then
        castedSpell  = nil
        lastCastCost = 0
    end
end)

local MAGIC_SKILLS = {
    destruction = true, restoration = true, conjuration = true,
    mysticism   = true, illusion    = true, alteration  = true,
}

interfaces.SkillProgression.addSkillUsedHandler(function(skillId, params)
    if not hasMGCartography                  then return end
    if not MAGIC_SKILLS[skillId]             then return end
    if not castedSpell or lastCastCost <= 0  then return end

    local count         = getVisitedCount()
    local refundPercent = getRefundPercent(count)
    if refundPercent <= 0 then return end

    local refundAmount = math.floor(lastCastCost * refundPercent)
    if refundAmount <= 0 then return end

    local magicka    = types.Actor.stats.dynamic.magicka(self)
    local maxMagicka = magicka.base + magicka.modifier
    magicka.current  = math.min(magicka.current + refundAmount, maxMagicka)

    print("MG Cartography: Refunded " .. refundAmount
        .. " magicka (" .. (refundPercent * 100) .. "% of " .. lastCastCost .. ")")
end)

-- ============================================================
--  CARTOGRAPHY CONSOLE COMMANDS
--
--  lua mg cartography dump  - print all stored Places of Power
--  lua mg cartography clear - wipe visited table, reset effects
-- ============================================================

local function onConsoleCommand(mode, command)
    local lower = command:lower()

    if lower:find("^lua mg cartography dump") then
        local count = getVisitedCount()
        if count == 0 then
            print("MG Cartography: No Places of Power stored.")
            return
        end
        print("MG Cartography: Stored Places of Power (" .. count .. " total):")
        local i = 0
        for cellId, cellName in pairs(visited) do
            i = i + 1
            print("  [" .. i .. "] Name: '" .. tostring(cellName)
                .. "'  |  ID: " .. tostring(cellId))
        end
        print("  appliedResist = " .. appliedResist
            .. " | appliedDetect = " .. appliedDetect
            .. " | appliedMagickaMod = " .. appliedMagickaMod)

    elseif lower:find("^lua mg cartography clear") then
        removeCartographyEffects()
        visited       = {}
        appliedResist = 0
        appliedDetect = 0
        print("MG Cartography: Visited table cleared. All bonuses reversed.")
        ui.showMessage("Magical Cartography data cleared.")
    end
end

-- ============================================================
--  MAGES GUILD PERKS
-- ============================================================

local function guildRank(rank)
    local reqs = {
        R().minimumFactionRank('mages guild', rank),
    }
    if core.contentFiles.has("tamriel_data.esm") then
        table.insert(reqs, R().minimumFactionRank('t_cyr_magesguild', rank))
        table.insert(reqs, R().minimumFactionRank('t_sky_magesguild', rank))
        table.insert(reqs, R().minimumFactionRank('t_ham_magesguild', rank))
    end
    if #reqs == 1 then return reqs[1] end
    return R().orGroup(table.unpack(reqs))
end

local mg1_id = ns .. "_mg_guild_initiate"
interfaces.ErnPerkFramework.registerPerk({
    id = mg1_id,
    localizedName = "Guild Initiate",
    localizedDescription = "You have passed the Guild's entrance rites. "
        .. "The library shelves are open to you.\
 "
        .. "(+3 Intelligence, +3 Endurance, +10 Fortify Magicka, "
        .. "+5 Destruction, +5 Alteration)",
    hidden = perkHidden(GUILD, 0, 1),
    art = "textures\\levelup\\mage", cost = 1,
    requirements = {
        guildRank(0),
        R().minimumLevel(1)
    },
    onAdd    = function() setRank(1); applyMagickaMod(10) end,
    onRemove = function() setRank(nil); applyMagickaMod(0) end,
})

local mg2_id = ns .. "_mg_scholastic_rigour"
interfaces.ErnPerkFramework.registerPerk({
    id = mg2_id,
    localizedName = "Scholastic Rigour",
    localizedDescription = "The Guild's structured study has sharpened your mind. "
        .. "You have learned to identify and catalogue the Places of Power "
        .. "that saturate Vvardenfell, drawing knowledge and resistance from each.\
 "
        .. "Requires Guild Initiate. "
        .. "(+5 Intelligence, +5 Endurance, +20 Fortify Magicka, "
        .. "+10 Destruction, +10 Alteration)\
\
"
        .. "Magical Cartography: Visiting Places of Power grants +1 Resist Magicka "
        .. "and +2 Detect Enchantment per location. Every 10 locations grants "
        .. "a 5%% magicka refund on successful spell casts (max 25%%).",
    hidden = perkHidden(GUILD, 3, 5),
    art = "textures\\levelup\\mage", cost = 2,
    requirements = {
        R().hasPerk(mg1_id),
        guildRank(3),
        R().minimumAttributeLevel('intelligence', 40),
        R().minimumLevel(5),
    },
    onAdd = function()
        setRank(2)
        applyMagickaMod(20)
        hasMGCartography = true
        -- appliedResist/appliedDetect already restored from save,
        -- so applyCartographyEffects computes only the correct delta
        applyCartographyEffects(getVisitedCount())
    end,
    onRemove = function()
        setRank(nil)
        applyMagickaMod(0)
        hasMGCartography = false
        removeCartographyEffects()
    end,
})

local mg3_id = ns .. "_mg_arcane_reservoir"
interfaces.ErnPerkFramework.registerPerk({
    id = mg3_id,
    localizedName = "Arcane Reservoir",
    localizedDescription = "Years of disciplined spellcasting have deepened your reserves. "
        .. "Your magicka pool expands with your intellect.\
 "
        .. "Requires Scholastic Rigour. "
        .. "(+10 Intelligence, +10 Endurance, +35 Fortify Magicka, "
        .. "+18 Destruction, +18 Alteration, "
        .. "Fortify Maximum Magicka 0.5x Intelligence)",
    hidden = perkHidden(GUILD, 6, 10),
    art = "textures\\levelup\\mage", cost = 3,
    requirements = {
        R().hasPerk(mg2_id),
        guildRank(6),
        R().minimumAttributeLevel('intelligence', 50),
        R().minimumLevel(10),
    },
    onAdd    = function() setRank(3); applyMagickaMod(35) end,
    onRemove = function() setRank(nil); applyMagickaMod(0) end,
})

local mg4_id = ns .. "_mg_archmagisters_peer"
interfaces.ErnPerkFramework.registerPerk({
    id = mg4_id,
    localizedName = "Archmagister's Peer",
    localizedDescription = "The senior mages regard you as a genuine equal. "
        .. "Your intellect feeds your power directly.\
 "
        .. "Requires Arcane Reservoir. "
        .. "(+15 Intelligence, +15 Endurance, +50 Fortify Magicka, "
        .. "+25 Destruction, +25 Alteration, "
        .. "Fortify Maximum Magicka 1.0x Intelligence "
        .. "[replaces Arcane Reservoir's 0.5x bonus])",
    hidden = perkHidden(GUILD, 9, 15),
    art = "textures\\levelup\\mage", cost = 4,
    requirements = {
        R().hasPerk(mg3_id),
        guildRank(9),
        R().minimumAttributeLevel('intelligence', 75),
        R().minimumLevel(15),
    },
    onAdd    = function() setRank(4); applyMagickaMod(50) end,
    onRemove = function() setRank(nil); applyMagickaMod(0) end,
})

-- ============================================================
--  ENGINE CALLBACKS
-- ============================================================

local function onUpdate(dt)
    if not hasMGCartography then return end

    cellCheckTimer = cellCheckTimer - dt
    if cellCheckTimer > 0 then return end
    cellCheckTimer = CELL_CHECK_INTERVAL

    local cell = self.cell
    if not cell then
        lastCellId = nil
        return
    end

    local cellId = cell.id
    if cellId == lastCellId then return end
    lastCellId = cellId

    checkCurrentCell(cell)
end

local function onSave()
    return {
        appliedMagickaMod = appliedMagickaMod,
        appliedResist     = appliedResist,
        appliedDetect     = appliedDetect,
        visited           = visited,
    }
end

local function onLoad(data)
    data              = data or {}
    appliedMagickaMod = data.appliedMagickaMod or 0
    appliedResist     = data.appliedResist     or 0
    appliedDetect     = data.appliedDetect     or 0
    visited           = data.visited           or {}
    print("MG Cartography: Loaded " .. getVisitedCount()
        .. " Places of Power from save.")
end

return {
    engineHandlers = {
        onUpdate         = onUpdate,
        onSave           = onSave,
        onLoad           = onLoad,
        onConsoleCommand = onConsoleCommand,
    },
}
