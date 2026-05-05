--[[
Tribunal Temple - Honoured Ancestors
Attached to all CREATURE instances.
On becoming active, Ancestor Ghosts, Bonelords, and Bonewalkers
(excluding summoned instances) ping nearby players.
Player script decides whether to calm them based on perk state.
Uses fight modifier rather than base so calming is fully reversible
when the perk is lost via respec or expulsion.
]]

local I          = require('openmw.interfaces')
local ns         = require("scripts.FactionPerks.namespace")
local pself      = require("openmw.self")
local types      = require("openmw.types")
local interfaces = require("openmw.interfaces")
local nearby     = require("openmw.nearby")

require("scripts.FactionPerks.shared")

-- ============================================================
--  TRIBUNAL TEMPLE TARGET CLASSIFICATION
--  Matches by record ID substring, consistent with the
--  Sixth House check in FPerks_HR.lua.
-- ============================================================

local HONOURED_ANCESTORS = {
    ["ancestor ghost"] = true,
    ["bonelord"]       = true,
    ["bonewalker"]     = true,
}

local function isHonouredAncestor()
    if not types.Creature.objectIsInstance(pself) then return false end
    local id = (types.Creature.record(pself).id or ""):lower()
    for name, _ in pairs(HONOURED_ANCESTORS) do
        if id:find(name, 1, true) then return true end
    end
    return false
end

-- ============================================================
-- TRIBUNAL TEMPLE ENGINE HANDLERS
-- ============================================================

local function onActive()
    if not isHonouredAncestor() then return end

    -- Exclude summoned instances: summoned creatures have a Follow
    -- AI package pointing back to the player. We must not calm those
    -- as they are already allied.
    local following = false
    interfaces.AI.forEachPackage(function(param)
        if param.type == "Follow" then following = true end
    end)
    if following then return end

    -- Always restore fight modifier first. This ensures that if the
    -- player lost the perk while outside this cell, any previously
    -- applied calm modifier is cleared before we re-evaluate.
    types.Actor.stats.ai.fight(pself).modifier = 0

    -- Ping nearby players. Player script decides whether to calm.
    -- If the perk is held, the player will send _TT_CalmAncestor back.
    -- If not, the restore above is the final state.
    for _, player in ipairs(nearby.players) do
        player:sendEvent(ns .. "_TT_AncestorSpawned", { creature = pself })
    end
end

-- ============================================================
--  TRIBUNAL TEMPLE EVENT HANDLERS
-- ============================================================

local function calmAncestor(data)
    -- Suppress aggression via modifier, preserving the base value
    -- so it can be cleanly restored if the perk is later lost.
    types.Actor.stats.ai.fight(pself).modifier = -200
    pself:sendEvent('RemoveAIPackages', 'Combat')
end

local function restoreAncestor(data)
    -- Zero the modifier to reverse calming. The base fight value
    -- was never changed, so the creature returns to its original
    -- aggression level.
    types.Actor.stats.ai.fight(pself).modifier = 0
end

-- ============================================================
--  COMBAT HIT HANDLER
--  FPerks_DoICSmite handles its own eligibility checks internally.
--  Fires for all creatures - undead, daedra, and vampires
--  are filtered inside isSmiteTarget in shared.lua.
-- ============================================================

I.Combat.addOnHitHandler(function(attack)
    FPerks_DoICSmite(attack)
end)

return {
    eventHandlers = {
        [ns .. "_TT_CalmAncestor"]    = calmAncestor,
        [ns .. "_TT_RestoreAncestor"] = restoreAncestor,
    },
    engineHandlers = {
        onActive = onActive,
    }
}
