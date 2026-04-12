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
--  honourScale(factionId)
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
--  EXPORTS
-- ============================================================
return {
    getRepCap    = getRepCap,
    honourScale  = honourScale,
    makeSetRank  = makeSetRank
}
