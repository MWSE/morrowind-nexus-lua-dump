local lib = require("Flin.lib")
local interop = require("Flin.interop")

local log = lib.log

-- a strategy for the NPC to play a card in the Flin game
-- a strategy consists of four parts:
-- 1. during phase 1, if the NPC goes first
-- 2. during phase 1, if the NPC goes second
-- 3. during phase 2, if the NPC goes first
-- 4. during phase 2, if the NPC goes second
-- the stragy has four functions, one for each part
-- each function takes the game object as an argument
-- and returns a table of preferences for the cards in the NPC's hand
-- the table is a list of tables, each table has the following keys:
-- - card: the card object
-- - preference: a number representing how much the NPC wants to play this card
-- the higher the number, the more the NPC wants to play the card

---@class CardPreference
---@field card Card
---@field preference number

---@class AiStrategyPhase
---@field phase EStrategyPhase
---@field name string
---@field fun fun(game: FlinGame): CardPreference[]
---@field evaluate fun(handle: mwseSafeObjectHandle): number

---@class FlinNpcAi
---@field phase1First AiStrategyPhase
---@field phase1Second AiStrategyPhase
---@field phase2First AiStrategyPhase
---@field phase2Second AiStrategyPhase
local strategy = {}

---@enum EStrategyPhase
strategy.EStrategyPhase = {
    PHASE1FIRST = 1,
    PHASE1SECOND = 2,
    PHASE2FIRST = 3,
    PHASE2SECOND = 4,
}

--- set the strategies for the NPC
---@param game FlinGame
function strategy:SetStrategies(game)
    self.phase1First = interop.chooseStrategy(strategy.EStrategyPhase.PHASE1FIRST, game.npcData.npcHandle)
    self.phase1Second = interop.chooseStrategy(strategy.EStrategyPhase.PHASE1SECOND, game.npcData.npcHandle)
    self.phase2First = interop.chooseStrategy(strategy.EStrategyPhase.PHASE2FIRST, game.npcData.npcHandle)
    self.phase2Second = interop.chooseStrategy(strategy.EStrategyPhase.PHASE2SECOND, game.npcData.npcHandle)
end

-- constructor
--- @param handle mwseSafeObjectHandle
function strategy:new(handle)
    log:debug("Setting NPC strategies")
    log:debug("\twillpower: %s", handle:getObject().mobile.willpower.current)
    log:debug("\tintelligence: %s", handle:getObject().mobile.intelligence.current)
    log:debug("\tendurance: %s", handle:getObject().mobile.endurance.current)
    log:debug("\tstrength: %s", handle:getObject().mobile.strength.current)
    log:debug("\tluck: %s", handle:getObject().mobile.luck.current)
    -- log:debug("\tagility: %s", handle:getObject().mobile.agility.current)
    -- log:debug("\tspeed: %s", handle:getObject().mobile.speed.current)
    -- log:debug("\tpersonality: %s", handle:getObject().mobile.personality.current)

    ---@type FlinNpcAi
    local newObj = {
        phase1First = interop.chooseStrategy(strategy.EStrategyPhase.PHASE1FIRST, handle),
        phase1Second = interop.chooseStrategy(strategy.EStrategyPhase.PHASE1SECOND, handle),
        phase2First = interop.chooseStrategy(strategy.EStrategyPhase.PHASE2FIRST, handle),
        phase2Second = interop.chooseStrategy(strategy.EStrategyPhase.PHASE2SECOND, handle)
    }

    setmetatable(newObj, self)
    self.__index = self
    return newObj
end

local function pShuffle(willpower)
    if willpower > 75 then
        return 0
    elseif willpower > 50 then
        return 75 - willpower
    elseif willpower > 25 then
        return 90 - willpower
    else
        return math.min(100, 100 - willpower)
    end
end

--- choose a card to play
---@param game FlinGame
---@return Card
function strategy:choose(game)
    local trickPCSlot = game.trickPCSlot
    local npcGoesSecond = trickPCSlot and trickPCSlot.card

    -- if willpower is low, reshufle the strategies
    local willpower = game.npcData.npcHandle:getObject().mobile.willpower.current
    if math.random(100) < pShuffle(willpower) then
        log:info("NPC reshuffling strategies")
        self:SetStrategies(game)
    end

    local strat = nil
    if game:IsPhase2() then
        if npcGoesSecond then
            strat = self.phase2Second
        else
            strat = self.phase2First
        end
    else
        if npcGoesSecond then
            strat = self.phase1Second
        else
            strat = self.phase1First
        end
    end

    local card = self:evaluate(strat, game)
    return card
end

local function cardFuzz(intelligence)
    if intelligence >= 75 then
        return 1
    elseif intelligence >= 50 then
        return 2
    elseif intelligence >= 30 then
        return 3
    elseif intelligence >= 15 then
        return 4
    else
        return 5
    end
end


--- evaluate the preferences and choose the best card
---@param strat AiStrategyPhase
---@param game FlinGame
---@return Card
function strategy:evaluate(strat, game)
    local preferences = strat.fun(game)
    local trickPCSlot = game.trickPCSlot
    local npcGoesSecond = trickPCSlot and trickPCSlot.card

    -- logging
    log:debug("AI strategy: %s", strat.name)
    log:debug("\tphase 2: %s", game:IsPhase2())
    log:debug("\tnpc goes %s", npcGoesSecond and "second" or "first")
    log:debug("\ttrump is %s", lib.suitToString(game.trumpSuit))
    lib.log:debug("\ttrick card: %s", trickPCSlot and trickPCSlot.card and trickPCSlot.card:toString() or "none")

    if game:IsPhase2() and npcGoesSecond then
        -- in phase 2 when the NPC goes 2nd we need to be strict
        local maxPreference = -1
        local card = nil
        for _, pref in ipairs(preferences) do
            if pref.preference > maxPreference then
                card = pref.card
                maxPreference = pref.preference
            end
        end
        return card
    else
        -- sort the preferences by preference
        table.sort(preferences, function(a, b) return a.preference > b.preference end)
        -- choose a card at random from the highest N cards
        -- n can be between 1 and 5 (1 is best, always choose the best card)
        local intelligence = game.npcData.npcHandle:getObject().mobile.intelligence.current
        local n = math.min(cardFuzz(intelligence), #preferences)
        local randomIndex = math.random(n)
        local card = preferences[randomIndex].card

        -- log the preferences
        for i, pref in ipairs(preferences) do
            log:trace("Card %s: preference %s", pref.card:toString(), pref.preference)
        end
        log:trace("Chose card index %s", randomIndex)

        return card
    end
end

return strategy
