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
        phase = EStrategyPhase.PHASE1SECOND,
        name = "balanced",
        fun = function(game)
            local npcHand = game.npcHand
            local trumpSuit = game.trumpSuit
            local trickPCSlot = game.trickPCSlot

            assert(trickPCSlot, "trickPCSlot is nil")

            local lowValueThreshold = EValue.X
            local valueToBeat = trickPCSlot.card.value

            local preferences = {}

            for i, card in ipairs(npcHand) do
                local preference = 0

                if valueToBeat < lowValueThreshold then
                    -- if the current trick is of low value then just dump a low non trump card
                    if card.suit ~= trumpSuit and card.value < lowValueThreshold then
                        -- the lower the better
                        -- 13 - 2,3,4
                        preference = EValue.Ace + 50 - card.value
                    elseif
                    -- we couldn't find a low non-trump card to dump so we try to win the trick with the same suit
                        card.suit == trickPCSlot.card.suit and card.value > valueToBeat then
                        -- the lower the better
                        -- 13 - 2,3,4,10,11
                        preference = EValue.Ace + 50 - card.value
                    else
                        -- we only have high value cards so we try to minimize loss
                        if card.suit ~= trumpSuit then
                            preference = EValue.Ace + EValue.Ace - card.value
                        else
                            preference = EValue.Ace - card.value
                        end
                    end
                else
                    -- if the current trick is of high value then try to win it with a non-trump card of the same suit
                    -- the higher the better
                    -- 10 + 2,3,4,10,11
                    if card.suit ~= trumpSuit and card.suit == trickPCSlot.card.suit and card.value > valueToBeat then
                        preference = 100 + card.value
                    elseif
                    -- now try to win it with a trump card
                    -- the higher the better
                    -- 2,3,4,10,11
                        card.suit == trumpSuit then
                        preference = 50 + card.value
                    else
                        -- try to minimize loss
                        -- the lower the better
                        -- 11 - 2,3,4,10,11
                        -- trunp cards are more valuable
                        if card.suit ~= trumpSuit then
                            preference = EValue.Ace + EValue.Ace - card.value
                        else
                            preference = EValue.Ace - card.value
                        end
                    end
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

-- aggressive: always try to win the trick
---@return AiStrategyPhase
function this.aggressive()
    ---@type AiStrategyPhase
    local s = {
        phase = EStrategyPhase.PHASE1SECOND,
        name = "aggressive",
        fun = function(game)
            local npcHand = game.npcHand
            local trumpSuit = game.trumpSuit
            local trickPCSlot = game.trickPCSlot

            assert(trickPCSlot, "trickPCSlot is nil")

            local valueToBeat = trickPCSlot.card.value

            local preferences = {}

            for i, card in ipairs(npcHand) do
                local preference = 0
                -- if the current trick is of high value then try to win it with a non-trump card of the same suit
                -- the higher the better
                -- 10 + 2,3,4,10,11
                if card.suit ~= trumpSuit and card.suit == trickPCSlot.card.suit and card.value > valueToBeat then
                    preference = 100 + card.value
                elseif
                -- now try to win it with a trump card
                -- the higher the better
                -- 2,3,4,10,11
                    card.suit == trumpSuit then
                    preference = 50 + card.value
                else
                    -- try to minimize loss
                    -- the lower the better
                    -- 11 - 2,3,4,10,11
                    -- trunp cards are more valuable
                    if card.suit ~= trumpSuit then
                        preference = EValue.Ace + EValue.Ace - card.value
                    else
                        preference = EValue.Ace - card.value
                    end
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
