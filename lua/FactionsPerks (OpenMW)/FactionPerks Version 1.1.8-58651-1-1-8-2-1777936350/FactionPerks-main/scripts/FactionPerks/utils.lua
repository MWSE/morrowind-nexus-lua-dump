--[[
    FactionPerks utils.lua
    
    Shared utilities for player-context faction scripts.
    Require this file in faction lua files, NOT in npc.lua.
    npc.lua uses shared.lua instead.

    Provides:
        utils.getRepCap(factionId)      - returns the faction reputation cap for
                                          the Honour The Great House scaling system.
                                          Accounts for TR_Factions if loaded.

        utils.makeSetRank(perkTable, flagHandlers)
                                        - returns a configured setRank function
                                          bound to the given perkTable and optional
                                          flagHandlers table. Call once per faction
                                          file at load time.
]]

local core  = require('openmw.core')
local types = require('openmw.types')
local self  = require('openmw.self')
local ns = require("scripts.FactionPerks.namespace")
local localization = core.l10n(ns)
-- ============================================================
--  REPUTATION CAPS
--  Used by Honour The Great House scaling to determine the
--  maximum faction reputation that contributes to the effect.
--  Beyond this cap the bonus does not increase further, to
--  prevent snowballing and to ensure mod compatibility.
--
--  Vanilla: all three Great Houses cap at 125 faction rep
--  (25 quests x 5 rep each).
--
--  TR_Factions raises these significantly. We detect the ESP
--  by name and swap to the appropriate cap table. If you use
--  another mod that alters Great House rep requirements, load
--  this mod after it and add a detection block below.
-- ============================================================

local VANILLA_CAPS = {
    hlaalu   = 125,
    redoran  = 125,
    telvanni = 125,
}

local TR_CAPS = {
    hlaalu   = 250,
    redoran  = 175,
    telvanni = 225,
}

local function getRepCap(factionId)
    if core.contentFiles.has("TR_Factions.esp") then
        return TR_CAPS[factionId] or 125
    end
    return VANILLA_CAPS[factionId] or 125
end

-- ============================================================
--  FACTION GROUPS
--  Maps each joinable faction to the list of faction IDs that
--  count as membership. For vanilla factions this is a single
--  entry. Mods that add regional branches (e.g. Tamriel
--  Rebuilt) are detected here and their branch IDs appended,
--  so every perkHidden and notExpelled call stays up to date
--  automatically.
--
--  To add support for a new mod that adds branches, append a
--  detection block below - no changes needed in faction files.
-- ============================================================

local FACTION_GROUPS = {
    thievesGuild   = { 'thieves guild' },
    moragTong      = { 'morag tong' },
    fightersGuild  = { 'fighters guild' },
    magesGuild     = { 'mages guild' },
    imperialLegion = { 'imperial legion' },
    imperialCult   = { 'imperial cult' },
    temple         = { 'temple' },
    hlaalu         = { 'hlaalu' },
    redoran        = { 'redoran' },
    telvanni       = { 'telvanni' },
}

-- Tamriel Rebuilt adds Cyrodiil and Skyrim branches for the
-- imperial guilds. Detected by Tamriel_Data.esm presence.
if core.contentFiles.has("Tamriel_Data.esm") then
    table.insert(FACTION_GROUPS.thievesGuild,   't_cyr_thievesguild')
    table.insert(FACTION_GROUPS.thievesGuild,   't_sky_thievesguild')
    table.insert(FACTION_GROUPS.fightersGuild,  't_cyr_fightersguild')
    table.insert(FACTION_GROUPS.fightersGuild,  't_sky_fightersguild')
    table.insert(FACTION_GROUPS.magesGuild,     't_cyr_magesguild')
    table.insert(FACTION_GROUPS.magesGuild,     't_sky_magesguild')
    table.insert(FACTION_GROUPS.magesGuild,     't_ham_magesguild')
    table.insert(FACTION_GROUPS.imperialLegion, 't_cyr_imperiallegion')
    table.insert(FACTION_GROUPS.imperialLegion, 't_sky_imperiallegion')
    table.insert(FACTION_GROUPS.imperialCult,   't_sky_imperialcult')
    table.insert(FACTION_GROUPS.imperialCult,   't_cyr_itinerantpriests')
    -- Add further TR branch IDs here as they are introduced
end


--
--  Returns a scale factor for Honour The Great House effects.
--
--  Pre-cap:  linear from 0.0 to 1.0 over 0 - repCap rep.
--  Post-cap: continues growing at 30% of the pre-cap rate.
--            No hard ceiling - completing every quest still
--            rewards the player, just with diminishing returns.
--
--  Example with repCap = 125:
--    rep   0 - 0.000
--    rep  63 - 0.504
--    rep 125 - 1.000  (cap values reached here)
--    rep 250 - 1.300  (30% rate continues beyond cap)
-- ============================================================

local function honourScale(factionId)
    local rep    = types.NPC.getFactionReputation(self, factionId)
    local cap    = getRepCap(factionId)
    if cap <= 0 then return 0 end

    local preCap = math.min(rep, cap) / cap             -- 0.0 - 1.0 within cap
    local excess = math.max(rep - cap, 0)
    local postCap = (excess / cap) * 0.3                -- 30% rate beyond cap

    return preCap + postCap
end

-- ============================================================
--  Returns a setRank function configured for the given faction.
--
--  perkTable    - indexed by rank number (1-4). Each entry may
--                 contain:
--                   passive  = { "SpellId1", "SpellId2", ... }
--                   flags    = { flagName = true, ... }
--
--  flagHandlers - optional table mapping flag names to setter
--                 functions, e.g.:
--                   { HasMT4 = function(v) HasMT4 = v end }
--                 Pass nil for factions with no flags.
--
--  The returned setRank(NewRank) function:
--    - Strips ALL passives from every rank in the table
--    - Resets ALL flags to false via their handlers
--    - If NewRank is nil, stops here (used during full respec)
--    - Otherwise applies the passives and flags for NewRank
-- ============================================================

local function makeSetRank(perkTable, flagHandlers)

    -- Increase the rank of the PerkTable, applying the new effects, and removing the old one.
    return function(NewRank)
    -- Removes all other effects by iterating through the table, then for each object within THAT table, runs through those

        -- Removing
        for _, rankData in pairs(perkTable) do
        -- Remove spell effects
            if rankData.passive then --If the object in that table location is a passive (spell effect) run a command to remove it
                for i = 1, #rankData.passive do
                    types.Actor.spells(self):remove(rankData.passive[i])
                end
            end

        -- Reset flags via handlers
            if rankData.flags and flagHandlers then
                for flag, _ in pairs(rankData.flags) do
                    if flagHandlers[flag] then
                        flagHandlers[flag](false)
                    end
                end
            end
        end

    -- Stop here if no rank (used for onRemove during full respec)
        if not NewRank or not perkTable[NewRank] then return end

        local rankData = perkTable[NewRank]

        -- Add spell effects
        if rankData.passive then --If the object in that table location is a passive (spell effect) run a command to add it
            for i = 1, #rankData.passive do
                types.Actor.spells(self):add(rankData.passive[i])
            end
        end

        -- Apply flags via handlers
        if rankData.flags and flagHandlers then
            for flag, value in pairs(rankData.flags) do
                if flagHandlers[flag] then
                    flagHandlers[flag](value)
                end
            end
        end
    end
end

-- ============================================================
--  perkHidden(factionIds, minimumRank, minimumLevel)
--
--  Returns a function suitable for the ErnPerkFramework
--  'hidden' field. The perk is hidden unless the player
--  meets ALL of the following simultaneously:
--    - Is a member of at least one faction in factionIds
--    - Holds at least minimumRank in that faction
--    - Is at or above minimumLevel
--
--  factionIds may be a single string or a table of strings.
--  For guilds with multiple branches (e.g. Fighters Guild +
--  TR Cyrodiil/Skyrim branches), pass all branch IDs as a
--  table - membership in any one branch satisfies the check.
--
--  Example (single faction):
--    perkHidden('redoran', 0, 1)
--
--  Example (multi-branch):
--    perkHidden({'fighters guild', 't_cyr_fightersguild', 't_sky_fightersguild'}, 0, 1)
-- ============================================================

local function perkHidden(factionIds, minimumRank, minimumLevel)
    -- Normalise to a table so the loop below is always the same
    if type(factionIds) == "string" then
        factionIds = { factionIds }
    end

    return function()
        -- Build a set for fast lookup
        local idSet = {}
        for _, id in ipairs(factionIds) do
            idSet[id] = true
        end

        -- Check membership and rank in any of the listed factions
        local qualifies = false
        for _, foundId in pairs(types.NPC.getFactions(self)) do
            if idSet[foundId] then
                local rank = types.NPC.getFactionRank(self, foundId)
                if rank >= minimumRank then
                    qualifies = true
                    break
                end
            end
        end
        if not qualifies then return true end  -- hide

        -- Must meet the level threshold
        local level = types.Actor.stats.level(self).current
        if level < minimumLevel then return true end  -- hide

        return false  -- show
    end
end

-- ============================================================
--  safeAddSpell(spellId) / safeRemoveSpell(spellId)
--
--  Idempotent wrappers around Actor.spells:add/remove.
--  safeAddSpell checks whether the spell is already present
--  before adding, preventing duplicate entries on load when
--  ErnPerkFramework re-fires onAdd for every held perk.
--  safeRemoveSpell is a no-op if the spell isn't present,
--  matching the same safe pattern.
--
--  Use these for all spells granted outside of setRank
--  (i.e. non-table spells granted once in onAdd/onRemove).
--  setRank itself removes before re-adding so is already safe.
-- ============================================================

local function safeAddSpell(spellId)
    local spells = types.Actor.spells(self)
    if not spells[spellId] then
        spells:add(spellId)
    end
end

local function safeRemoveSpell(spellId)
    local spells = types.Actor.spells(self)
    if spells[spellId] then
        spells:remove(spellId)
    end
end

-- ============================================================
--  EXPORTS
-- ============================================================
return {
    getRepCap       = getRepCap,
    honourScale     = honourScale,
    makeSetRank     = makeSetRank,
    notExpelled     = notExpelled,
    perkHidden      = perkHidden,
    safeAddSpell    = safeAddSpell,
    safeRemoveSpell = safeRemoveSpell,
    FACTION_GROUPS  = FACTION_GROUPS,
}