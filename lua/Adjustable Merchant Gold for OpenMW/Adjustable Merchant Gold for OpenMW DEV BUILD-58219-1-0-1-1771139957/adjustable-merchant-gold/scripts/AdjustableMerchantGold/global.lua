local types = require('openmw.types')
local world = require('openmw.world')

local DEFAULT_MULTIPLIER = 5
local multiplier = DEFAULT_MULTIPLIER

-- Per-actor tracking: actorId -> bonus gold we added.
-- Lets us do delta-based adjustments without overwriting trade changes.
local bonuses = {}

-- The single merchant the player is currently interacting with (if any).
-- Only this actor is polled per frame, avoiding the cost of iterating all
-- active actors while still catching engine restocks before the barter UI
-- renders the stale value.
local watchedMerchant = nil

-----------------------------------------------------------
-- Core logic
-----------------------------------------------------------

local function getBaseGold(actor)
    if types.NPC.objectIsInstance(actor) then
        return types.NPC.record(actor).baseGold
    elseif types.Creature.objectIsInstance(actor) then
        return types.Creature.record(actor).baseGold
    end
    return 0
end

--- Calculate the bonus gold to add on top of baseGold.
local function calcBonus(baseGold)
    return math.floor(baseGold * multiplier) - baseGold
end

--- Apply the multiplier bonus to an actor for the first time, or after
--- the engine resets their gold (24h restock).
local function applyToActor(actor)
    local baseGold = getBaseGold(actor)
    if baseGold <= 0 then return end

    local id = actor.id
    local currentGold = types.Actor.getBarterGold(actor)
    local bonus = calcBonus(baseGold)
    if bonuses[id] == nil then
        -- First time seeing this merchant — apply the bonus.
        types.Actor.setBarterGold(actor, currentGold + bonus)
        bonuses[id] = bonus
    elseif currentGold == baseGold and bonuses[id] ~= 0 then
        -- Gold is back to baseGold but we had added a non-zero bonus before.
        -- The engine restocked (24h reset). Re-apply.
        types.Actor.setBarterGold(actor, baseGold + bonus)
        bonuses[id] = bonus
    end
end

--- Adjust all active merchants when the multiplier setting changes.
--- Uses delta so trading gains/losses are preserved.
local function onMultiplierChanged()
    for _, actor in ipairs(world.activeActors) do
        local baseGold = getBaseGold(actor)
        if baseGold > 0 then
            local id = actor.id
            local oldBonus = bonuses[id] or 0
            local newBonus = calcBonus(baseGold)
            local delta = newBonus - oldBonus
            if delta ~= 0 then
                local currentGold = types.Actor.getBarterGold(actor)
                types.Actor.setBarterGold(actor, math.max(0, currentGold + delta))
            end
            bonuses[id] = newBonus
        end
    end
end

-----------------------------------------------------------
-- Engine handlers & events
-----------------------------------------------------------

return {
    engineHandlers = {
        onActorActive = function(actor)
            applyToActor(actor)
        end,
        -- Only poll the single merchant the player is talking to.
        -- Catches engine restocks in the same frame, before the barter
        -- UI renders the stale baseGold value.
        onUpdate = function()
            if watchedMerchant then
                applyToActor(watchedMerchant)
            end
        end,
        onSave = function()
            return { multiplier = multiplier, bonuses = bonuses }
        end,
        onLoad = function(data)
            if data then
                multiplier = data.multiplier or DEFAULT_MULTIPLIER
                bonuses = data.bonuses or {}
            end
        end,
    },
    eventHandlers = {
        AdjustableMerchantGold_SetMultiplier = function(data)
            if data.multiplier and data.multiplier ~= multiplier then
                multiplier = data.multiplier
                onMultiplierChanged()
            end
        end,
        AdjustableMerchantGold_WatchMerchant = function(data)
            if data.actor then
                watchedMerchant = data.actor
            end
        end,
        AdjustableMerchantGold_UnwatchMerchant = function()
            watchedMerchant = nil
        end,
    },
}
