local card = require("Hanafuda.card")
local koi = require("Hanafuda.KoiKoi.koikoi")
local combination = require("Hanafuda.KoiKoi.combination")
local houseRule = require("Hanafuda.KoiKoi.houseRule")

---@class KoiKoi.Settings
---@field round integer
---@field initialCards integer
---@field initialDealEach integer
---@field houseRule Config.KoiKoi.HouseRule

-- It is not necessary to keep captured piles separate, but it will make score calculation easier.
---@class KoiKoi.PlayerPool
---@field hand integer[]
---@field [CardType] integer[]

--- ruleset aka model
---@class KoiKoi.Game
---@field parent KoiKoi.Player means dealer + alpha
---@field current KoiKoi.Player
---@field round integer
---@field settings KoiKoi.Settings
---@field deck integer[] card deck
---@field pools KoiKoi.PlayerPool[]
---@field groundPool integer[]
---@field brains KoiKoi.IBrain[]
---@field combinations { KoiKoi.Player : { [KoiKoi.CombinationType] : integer } }
---@field points { KoiKoi.Player : integer }
---@field calls { KoiKoi.Player : integer }
---@field decidingParentCardId integer?
---@field decidingParent integer[] card deck
---@field logger mwseLogger
local KoiKoi = {}

---@type KoiKoi.Game
local defaults = {
    parent = koi.player.you,
    current = koi.player.you,
    round = 1,
    settings = {
        round = 3,
        initialCards = 8,
        initialDealEach = 2, -- or 4
        houseRule = {},
    },
    deck = {},
    pools = {
        -- you
        {
            hand = {},
            [card.type.bright] = {},
            [card.type.animal] = {},
            [card.type.ribbon] = {},
            [card.type.chaff] = {},
        },
        -- opponent
        {
            hand = {},
            [card.type.bright] = {},
            [card.type.animal] = {},
            [card.type.ribbon] = {},
            [card.type.chaff] = {},
        }
    },
    groundPool = {},
    brains = {},
    combinations = {},
    points = {
        [koi.player.you] = 0,
        [koi.player.opponent] = 0,
    },
    calls = {
        [koi.player.you] = 0,
        [koi.player.opponent] = 0,
    },
    decidingParentCardId = nil,
    decidingParent = {},
    logger = nil, ---@diagnostic disable-line: assign-type-mismatch
}

---@param settings KoiKoi.Settings
local function ValidateSettings(settings)
    assert(settings.round > 0)
    assert(settings.initialCards > 0)
    assert(settings.initialDealEach > 0)
    assert(settings.initialCards % settings.initialDealEach == 0) -- mod allowed, but it only complicate.
end
ValidateSettings(defaults.settings)

---@param rule Config.KoiKoi
---@param opponentBrain KoiKoi.IBrain?
---@param playerBrain KoiKoi.IBrain?
---@param logger mwseLogger
---@return KoiKoi.Game
function KoiKoi.new(rule, opponentBrain, playerBrain, logger)
    ---@type KoiKoi.Game
    local instance = table.deepcopy(defaults)
    instance.settings.houseRule = table.deepcopy(rule.houseRule) -- do not change in game
    instance.settings.round = rule.round
    instance.logger = logger
    ValidateSettings(instance.settings)
    setmetatable(instance, { __index = KoiKoi })
    instance:SetBrains(opponentBrain, koi.player.opponent)
    instance:SetBrains(playerBrain, koi.player.you)
    return instance
end

-- event base or command base
-- important split view and logic for replacing visualize using MVC or like as

---@param self KoiKoi.Game
---@param brain KoiKoi.IBrain?
---@param player KoiKoi.Player
function KoiKoi.SetBrains(self, brain, player)
    self.brains[player] = brain
end

---@param self KoiKoi.Game
function KoiKoi.Initialize(self)
    self.deck = card.CreateDeck()
    self.deck = card.ShuffleDeck(self.deck)
    self.pools = table.deepcopy(defaults.pools)
    self.calls = table.deepcopy(defaults.calls)
    self.groundPool = {}
    self.combinations = {}
    for _, b in pairs(self.brains) do
        if b then
            b:Reset()
        end
    end
end

function KoiKoi.ResetPoints(self)
    self.points = table.deepcopy(defaults.points)
end

-- The choice of the parents of the Hanafuda is flawed.
-- In the case of the same month, it is determined by card point, but there are cases where both players pick chaff. You must keep drawing cards until it is resolved.
-- That is boring in a video game, so limit the cards to avoid such a situation.
---@param self KoiKoi.Game
---@param num integer
---@return integer[]
function KoiKoi.ChoiceDecidingParentCards(self, num)
    local deck = card.CreateDeck()
    local banned = {
        4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 47, 48,
    }
    -- Since it is a sequential number before shuffling, it can be established by removing it from the back as an index, but this is not strictly correct. Delete it as a normal value.
    for index, value in ipairs(banned) do
        table.removevalue(deck, value)
    end
    assert(num <= table.size(deck))
    deck = card.ShuffleDeck(deck)

    self.decidingParent = {}
    for i = 1, num do
        table.insert(self.decidingParent, deck[i])
    end
    return self.decidingParent
end


-- Better to be able to choose between two cut cards to decide.
---@param self KoiKoi.Game
---@param selectedCardId integer
function KoiKoi.DecideParent(self, selectedCardId)

    local most = selectedCardId
    local rhs = card.GetCardData(most)
    for index, value in ipairs(self.decidingParent) do
        local lhs = card.GetCardData(value)
        if (lhs.suit < rhs.suit) or (lhs.suit == rhs.suit and lhs.type < rhs.type) then
            most = value
            rhs = lhs
        end
    end

    self.decidingParentCardId = selectedCardId
    self.parent = selectedCardId == most and koi.player.you or koi.player.opponent
    --self.parent = leftRight and koi.player.you or koi.player.opponent -- fixed
    self.current = self.parent
    self.logger:debug("Parent is ".. tostring(self.parent))
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
function KoiKoi.SetCurrentPlayer(self, player)
    self.current = player
end

-- Better with animation to hand out one card at a time.
function KoiKoi.DealInitialCards(self)
    local initialCards = self.settings.initialCards
    local initialDealEach = self.settings.initialDealEach
    local first = self.pools[koi.GetOpponent(self.parent)].hand
    local second = self.pools[self.parent].hand

    -- test for multiple captureing
    --[[
    initialDealEach = 8
    self.deck = {
        1, 2, 3, 4, 5, 6, 7, 8,
        9, 10, 11, 13, 14, 15, 20, 35,
        17, 18, 19, 21, 22, 23, 33, 34,
        25, 26, 27, 29, 30, 31, 24, 36,
    }
    --]]

    while table.size(first) < initialCards do
        for i = 1, initialDealEach do
            table.insert(first, card.DealCard(self.deck))
        end
        for i = 1, initialDealEach do
            table.insert(self.groundPool, card.DealCard(self.deck))
        end
        for i = 1, initialDealEach do
            table.insert(second, card.DealCard(self.deck))
        end
    end
    assert(table.size(first) == initialCards)
    assert(table.size(self.groundPool) == initialCards)
    assert(table.size(second) == initialCards)
end

---@param self KoiKoi.Game
---@return boolean
function KoiKoi.CheckUnluckyGround(self)
    -- countup same suits
    local suits = {}
    for _, cardId in ipairs(self.groundPool) do
        local data = card.GetCardData(cardId)
        local v = table.getset(suits, data.suit, 0)
        suits[data.suit] = v + 1
    end

    for s, value in pairs(suits) do
        if value >= 4 then
        self.logger:debug("There are 4 same suits: %d", s)
        return true
        end
    end
    return false
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@return { [KoiKoi.LuckyHands] : integer }?
---@return integer
function KoiKoi.CheckLuckyHands(self, player)
    local lh = combination.CalculateLuckyHands(self.pools[player].hand, self.settings.houseRule, self.logger)
    local p = 0
    if lh then
        for key, value in pairs(lh) do
            p = p + value
        end
    else
        self.logger:trace("%d is no lucky hands", player)
    end
    return lh, p
end

---@param self KoiKoi.Game
---@return boolean luckyhands
---@return KoiKoi.Player? winner
---@return { [KoiKoi.Player] : {[KoiKoi.LuckyHands] : integer}? } combo
---@return { [KoiKoi.Player] : integer } point
function KoiKoi.CheckLuckyHandsEach(self)
    local lh0, total0 = self:CheckLuckyHands(koi.player.you)
    local lh1, total1 = self:CheckLuckyHands(koi.player.opponent)

    -- test data
    --[[
    lh0 = {
        [koi.luckyHands.fourOfAKind] = 6,
        [koi.luckyHands.fourPairs] = 6,
    }
    total0 = 12
    --]]
    --[[
    lh1 = {
        --[koi.luckyHands.fourOfAKind] = 6,
        [koi.luckyHands.fourPairs] = 6,
    }
    total1 = 6
    --]]

    local lh = {[koi.player.you] = lh0, [koi.player.opponent] = lh1}
    local points = {[koi.player.you] = total0, [koi.player.opponent] = total1}

    local accept = false
    local tie = lh0 ~= nil and lh1 ~= nil
    local winner = nil
    if lh0 or lh1 then
        accept = true
        if not tie then
            if lh0 then
                winner = koi.player.you
            else
                winner = koi.player.opponent
            end
        end
    end
    return accept, winner, lh, points
end

---@param self KoiKoi.Game
---@return integer?
function KoiKoi.DrawCard(self)
    return card.DealCard(self.deck)
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@param drawnCardId integer?
---@param deltaTime number
---@param timestamp number
---@return KoiKoi.MatchCommand?
function KoiKoi.Simulate(self, player, drawnCardId, deltaTime, timestamp)
    if self.brains[player] then
        ---@type KoiKoi.AI.Params
        local params = {
            deltaTime = deltaTime,
            timestamp = timestamp,
            drawnCard = drawnCardId,
            pool = self.pools[player],
            opponentPool = self.pools[koi.GetOpponent(player)],
            groundPool = self.groundPool,
            deck = self.deck,
            combination = nil,
        }
        local command = self.brains[player]:Simulate(params)
        return command
    end
    return nil
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@param combinations { [KoiKoi.CombinationType] : integer }
---@param deltaTime number
---@param timestamp number
---@return KoiKoi.CallCommand?
function KoiKoi.Call(self, player, combinations, deltaTime, timestamp)
    if self.brains[player] then
        ---@type KoiKoi.AI.Params
        local params = {
            deltaTime = deltaTime,
            timestamp = timestamp,
            drawnCard = nil,
            pool = self.pools[player],
            opponentPool = self.pools[koi.GetOpponent(player)],
            groundPool = self.groundPool,
            deck = self.deck,
            combination = combinations,
        }
        local command = self.brains[player]:Call(params)
        return command
    end
    return nil
end

---@param self KoiKoi.Game
---@return KoiKoi.Player
function KoiKoi.SwapPlayer(self)
    self:SetCurrentPlayer(koi.GetOpponent(self.current))
    return self.current
end

---@param self KoiKoi.Game
---@param cardId integer
---@param targetId integer
---@return boolean
function KoiKoi.CanMatch(self, cardId, targetId)
    if table.find(self.groundPool, cardId) then
        self.logger:error("%d find in ground. it must not be", cardId)
    end
    if not table.find(self.groundPool, targetId) then
        self.logger:error("%d does not find in ground.", cardId)
    end
    return koi.CanMatchSuit(cardId, targetId)
end

---@param self KoiKoi.Game
---@param cardId integer
---@return boolean
function KoiKoi.CanDiscard(self, cardId)
    for _, id in pairs(self.groundPool) do
        if koi.CanMatchSuit(cardId, id) then
            return false
        end
    end
    return true
end


---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@return { [KoiKoi.CombinationType] : integer }?
function KoiKoi.CheckCombination(self, player)
    local pool = self.pools[player]
    local combo = combination.Calculate(pool, self.settings.houseRule, self.logger)
    local latest = self.combinations[player]
    local diff = combination.Different(combo, latest, self.logger)
    if diff then
        self.logger:debug("%d Update new combos", player)
        self.combinations[player] = combo
        return combo
    end
    return nil
end

---@param self KoiKoi.Game
function KoiKoi.CheckEnd(self)
    -- ends when both players hand empty
    for _, p in pairs(self.pools) do
        if table.size(p.hand) > 0 then
            return false
        end
    end
    return true
    -- return table.size(self.deck) == 0 -- or empty deck
end

---@param self KoiKoi.Game
---@param cardId integer?
---@return integer[]?
function KoiKoi.CanCaptureExtra(self, cardId)
    if cardId then
        local ids = {}
        for _, id in pairs(self.groundPool) do
            if koi.CanMatchSuit(cardId, id) then
                table.insert(ids, id)
            end
        end
        if table.size(ids) >= 3 then
            self.logger:debug("find extra captureble cards " .. table.concat(ids, ", "))
            return ids
        end
    end
    return nil
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@param cardId integer?
---@param ground boolean
---@param drawn boolean
function KoiKoi.Capture(self, player, cardId, ground, drawn)
    if cardId then
        local pool = self.pools[player]
        table.insert(pool[card.GetCardData(cardId).type], cardId)
        if ground then
            self.logger:trace("captured then removeing from ground ".. tostring(cardId))
            -- self.logger:trace(table.concat(self.groundPool, ", "))
            local removed = table.removevalue(self.groundPool, cardId)
            if not removed then
                self.logger:error("not found in ground")
            end
        elseif not drawn then
            self.logger:trace("captured then removeing from hand ".. tostring(cardId))
            -- self.logger:trace(table.concat(pool.hand, ", "))
            local removed = table.removevalue(pool.hand, cardId)
            if not removed then
                self.logger:error("not found in hand")
            end
        end
        return true
    end
    return false
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@param cardId integer?
---@param drawn boolean
function KoiKoi.Discard(self, player, cardId, drawn)
    if cardId then
        if not drawn then
            local pool = self.pools[player]
            self.logger:trace("removeing ".. tostring(cardId))
            -- self.logger:trace(table.concat(pool.hand, ", "))
            local removed = table.removevalue(pool.hand, cardId)
            if not removed then
                self.logger:error("not found in hand")
            end
        end
        table.insert(self.groundPool, cardId)
        return true
    end
    return false
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@param cardId integer?
---@return boolean
function KoiKoi.HasCard(self, player, cardId)
    if cardId then
        local pool = self.pools[player]
        return table.find(pool.hand, cardId) ~= nil
    end
    return false
end

---@param self KoiKoi.Game
---@return boolean
function KoiKoi.EmptyDeck(self)
    return table.size(self.deck) == 0 -- use empty better
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@return boolean
function KoiKoi.EmptyHand(self, player)
    return table.size(self.pools[player].hand) == 0 -- use empty better
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@return integer
function KoiKoi.AddKoiKoiCount(self, player)
    self.calls[player] = self.calls[player] + 1
    return self.calls[player]
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@return integer basePoint
---@return integer multiplier
function KoiKoi.CalculateRoundPoint(self, player)
    ---@param combo { [KoiKoi.CombinationType] : integer }
    ---@return integer
    local function SumTotalPoint(combo)
        local total = 0
        for _, value in pairs(combo) do
            total = total + value
        end
        return total
    end

    local point = 0
    local mult = 1
    if self.combinations[player] then
        point = SumTotalPoint(self.combinations[player])
        if self.settings.houseRule.multiplier == houseRule.multiplier.doublePointsOver7 then
            if point >= 7 then
                mult = 2
            end
        elseif self.settings.houseRule.multiplier == houseRule.multiplier.eachTimeKoiKoi then
            mult = 1 + self.calls[koi.player.you] + self.calls[koi.player.opponent]
        end
    end
    return point, mult
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
function KoiKoi.SetRoundWinner(self, player)
    local point, mult = self:CalculateRoundPoint(player)
    self.points[player] = self.points[player] + point * mult
    self.parent = player
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@param points integer
function KoiKoi.SetRoundWinnerByLuckyHands(self, player, points)
    self.points[player] = self.points[player] + points
    self.parent = player
end

---@param self KoiKoi.Game
---@return boolean
function KoiKoi.NextRound(self)
    if self.round < self.settings.round then
        self.round = self.round + 1
        self.logger:trace("next round %d", self.round)
        return true
    end
    return false
end

---@param self KoiKoi.Game
---@return KoiKoi.Player? -- nil is draw
function KoiKoi.GetGameWinner(self)
    local a = self.points[koi.player.you]
    local b = self.points[koi.player.opponent]
    local winner = nil
    if (a ~= b) then
        if a > b then
            winner = koi.player.you
        else
            winner = koi.player.opponent
        end
    end
    self.logger:debug("score: player %d, opponent %d", a, b)
    self.logger:debug("winner " .. tostring(winner))
    return winner
end

---@param self KoiKoi.Game
---@param player KoiKoi.Player
---@return boolean
function KoiKoi.HasBrain(self, player)
    return self.brains[player] ~= nil
end

return KoiKoi
