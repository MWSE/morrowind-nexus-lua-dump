local lib = require("Flin.lib")
local strategy = require("Flin.ai.strategy")

local EValue = lib.EValue
local log = lib.log
local EStrategyPhase = strategy.EStrategyPhase

local this = {}

---@return AiStrategyPhase
function this.random()
    ---@type AiStrategyPhase
    local s = {
        phase = EStrategyPhase.PHASE2FIRST,
        name = "random",
        fun = function(game)
            local npcHand = game.npcHand

            local preferences = {}
            for i, card in ipairs(npcHand) do
                local preference = 0
                table.insert(preferences, { card = card, preference = preference })
            end

            return preferences
        end,
        evaluate = function(handle)
            return 0.1
        end
    }
    return s
end

--- aggressive: try to play high cards
---@return AiStrategyPhase
function this.aggressive()
    ---@type AiStrategyPhase
    local s = {
        phase = EStrategyPhase.PHASE2FIRST,
        name = "aggressive",
        fun = function(game)
            local npcHand = game.npcHand
            local trumpSuit = game.trumpSuit
            local trickPCSlot = game.trickPCSlot

            local preferences = {}
            for i, card in ipairs(npcHand) do
                local preference = 0

                -- the higher the better
                if card.suit == trumpSuit then
                    preference = card.value + 50
                else
                    preference = card.value
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

--- defensive: try to play low cards
---@return AiStrategyPhase
function this.defensive()
    ---@type AiStrategyPhase
    local s = {
        phase = EStrategyPhase.PHASE2FIRST,
        name = "defensive",
        fun = function(game)
            local npcHand = game.npcHand
            local trumpSuit = game.trumpSuit
            local trickPCSlot = game.trickPCSlot

            local preferences = {}
            for i, card in ipairs(npcHand) do
                local preference = 0

                -- the lower the better
                if card.suit == trumpSuit then
                    preference = EValue.Ace - card.value
                else
                    preference = 50 + EValue.Ace - card.value
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

---@return AiStrategyPhase
function this.smart()
    ---@type AiStrategyPhase
    local s = {
        phase = EStrategyPhase.PHASE2FIRST,
        name = "smart",
        fun = function(game)
            local npcHand = game.npcHand

            local preferences = {}
            for i, card in ipairs(npcHand) do
                local preference = 0

                --TODO here everything depends on how much the npc knows
                -- about the player hand
                -- and the already played cards

                -- I win the trick only if
                -- 1. I know the player has only a lower card of the same suit
                -- 2. I know the player has no card of the same suit and no trump card

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
            local attribute = actor.intelligence.current
            return attribute / sum
        end
    }
    return s
end

return this
