-- scripts/custom_contraband.lua
--
-- Treat specific item IDs as "contraband":
-- whenever the player's bounty is cleared (paying fine or going to jail),
-- all of these items are automatically removed from the player's inventory.

local world = require('openmw.world')
local types = require('openmw.types')

-- *** EDIT THIS LIST ***
-- All keys must be LOWERCASE record IDs.
local CONTRABAND_IDS = {
['blackjack-wooden'] = true,
    ['blackjack-iron'] = true,
    ['blackjack-imperial'] = true,
    ['blackjack-dwemer'] = true,
    ['blackjack-wooden-operative'] = true,
    ['blackjack-iron-operative'] = true,
    ['blackjack-imperial-operative'] = true,
    ['blackjack-dwemer-operative'] = true,
    ['blackjack-wooden-masterthief'] = true,
    ['blackjack-iron-masterthief'] = true,
    ['blackjack-imperial-masterthief'] = true,
    ['blackjack-dwemer-masterthief'] = true,
    ['blackjack-wooden-weighted'] = true,
    ['blackjack-iron-weighted'] = true,
    ['blackjack-imperial-weighted'] = true,
    ['blackjack-dwemer-weighted'] = true,
    ['blackjack-wooden-nimble'] = true,
    ['blackjack-iron-nimble'] = true,
    ['blackjack-imperial-nimble'] = true,
    ['blackjack-dwemer-nimble'] = true,
    ['blackjack-wooden-masterwork'] = true,
    ['blackjack-iron-masterwork'] = true,
    ['blackjack-imperial-masterwork'] = true,
    ['blackjack-dwemer-masterwork'] = true,
    ['blackjack-wooden-extended'] = true,
    ['blackjack-iron-extended'] = true,
    ['blackjack-imperial-extended'] = true,
    ['blackjack-dwemer-extended'] = true
}

-- Internal state
local lastCrimeLevel = 0

local function getPlayer()
    -- Find the player among active actors
    for _, actor in ipairs(world.activeActors) do
        if actor.type == types.Player then
            return actor
        end
    end
    return nil
end

local function confiscateContraband(player)
    local inv = types.Actor.inventory(player)
    -- Get all items in inventory
    local allItems = inv:getAll()
    for _, item in ipairs(allItems) do
        -- recordId is always lowercase
        if CONTRABAND_IDS[item.recordId] then
            -- Remove entire stack of this item
            item:remove()
        end
    end
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            local player = getPlayer()
            if not player or not player:isValid() then
                return
            end

            local crime = types.Player.getCrimeLevel(player)

            -- Bounty just dropped from >0 to 0 => treat as "arrest resolved"
            if lastCrimeLevel > 0 and crime == 0 then
                confiscateContraband(player)
            end

            lastCrimeLevel = crime
        end,
    }
}