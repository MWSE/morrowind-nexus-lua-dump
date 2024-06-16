local lib = require("Flin.lib")
local strategy = require("Flin.ai.strategy")

local EValue = lib.EValue
local log = lib.log
local EStrategyPhase = strategy.EStrategyPhase

local this = {}

---@return AiStrategyPhase
function this.balanced()
    ---@type AiStrategyPhase
    local s = {
        phase = EStrategyPhase.PHASE1FIRST,
        name = "balanced",
        fun = function(game)
            local npcHand = game.npcHand
            local trumpSuit = game.trumpSuit

            local preferences = {} ---@type CardPreference[]
            for i, card in ipairs(npcHand) do
                local preference = 0

                -- if we have a high trump card then play it and try to win the trick
                if card.suit == trumpSuit then
                    -- my confidence is higher the higher the card is
                    -- 2,3,4,10,11
                    -- 2,3,4,10,11
                    preference = card.value
                else
                    -- we don't have a high trump card so try to dump a low non-trump card
                    -- my confidence is higher the lower the card is
                    -- 2,3,4,10,11
                    -- 15,14,13,7,6
                    preference = 17 - card.value
                end

                table.insert(preferences, { card = card, preference = preference })
            end

            return preferences
        end,
        evaluate = function(handle)
            local actor = handle:getObject().mobile
            if not actor then
                return 1
            end
            local sum = lib.GetAttributesSum(actor)
            local attribute = actor.willpower.current
            return attribute / sum
        end
    }
    return s
end

-- defensive: try to dump low non-trump cards always
---@return AiStrategyPhase
function this.defensive()
    ---@type AiStrategyPhase
    local s = {
        phase = EStrategyPhase.PHASE1FIRST,
        name = "defensive",
        fun = function(game)
            local npcHand = game.npcHand
            local trumpSuit = game.trumpSuit
            local preferences = {} ---@type CardPreference[]
            for i, card in ipairs(npcHand) do
                local preference = 0

                if card.suit ~= trumpSuit then
                    -- the lower the better
                    -- 11 - 2,3,4,10,11
                    preference = 20 + EValue.Ace - card.value
                else
                    -- minimize loss
                    preference = EValue.Ace - card.value
                end

                table.insert(preferences, { card = card, preference = preference })
            end

            return preferences
        end,
        evaluate = function(handle)
            local actor = handle:getObject().mobile
            if not actor then
                return 1
            end
            local sum = lib.GetAttributesSum(actor)
            local attribute = actor.endurance.current
            return attribute / sum
        end
    }
    return s
end

-- aggressive: try to always play high trump cards
---@return AiStrategyPhase
function this.aggressive()
    ---@type AiStrategyPhase
    local s = {
        phase = EStrategyPhase.PHASE1FIRST,
        name = "aggressive",
        fun = function(game)
            local npcHand = game.npcHand
            local trumpSuit = game.trumpSuit
            local preferences = {} ---@type CardPreference[]
            for i, card in ipairs(npcHand) do
                local preference = 0

                if card.suit ~= trumpSuit then
                    -- the higher the better
                    preference = card.value
                else
                    -- the higher the better
                    preference = 50 + card.value
                end

                table.insert(preferences, { card = card, preference = preference })
            end

            return preferences
        end,
        evaluate = function(handle)
            local actor = handle:getObject().mobile
            if not actor then
                return 1
            end
            local sum = lib.GetAttributesSum(actor)
            local attribute = actor.strength.current
            return attribute / sum
        end
    }
    return s
end

return this
