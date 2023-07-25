--- weighted selection AI
---@class KoiKoi.WeightedBrain : KoiKoi.IBrain
---@field weights number[]
local this = {}
local brain = require("Hanafuda.KoiKoi.brain.brain")
setmetatable(this, {__index = brain})

local koi = require("Hanafuda.KoiKoi.koikoi")

local baseWeights = {
    50, -- { suit = data.cardSuit.january,     type = data.cardType.bright, symbol = data.cardSymbol.crane },
    30, -- { suit = data.cardSuit.january,     type = data.cardType.ribbon, symbol = data.cardSymbol.redPoetry },
    5, -- { suit = data.cardSuit.january,     type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    5, -- { suit = data.cardSuit.january,     type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    20, -- { suit = data.cardSuit.february,    type = data.cardType.animal, symbol = data.cardSymbol.warbler },
    30, -- { suit = data.cardSuit.february,    type = data.cardType.ribbon, symbol = data.cardSymbol.redPoetry },
    0, -- { suit = data.cardSuit.february,    type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    0, -- { suit = data.cardSuit.february,    type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    70, -- { suit = data.cardSuit.march,       type = data.cardType.bright, symbol = data.cardSymbol.curtain },
    30, -- { suit = data.cardSuit.march,       type = data.cardType.ribbon, symbol = data.cardSymbol.redPoetry },
    0, -- { suit = data.cardSuit.march,       type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    0, -- { suit = data.cardSuit.march,       type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    20, -- { suit = data.cardSuit.april,       type = data.cardType.animal, symbol = data.cardSymbol.cuckoo },
    10, -- { suit = data.cardSuit.april,       type = data.cardType.ribbon, symbol = data.cardSymbol.red },
    0, -- { suit = data.cardSuit.april,       type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    0, -- { suit = data.cardSuit.april,       type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    20, -- { suit = data.cardSuit.may,         type = data.cardType.animal, symbol = data.cardSymbol.bridge },
    10, -- { suit = data.cardSuit.may,         type = data.cardType.ribbon, symbol = data.cardSymbol.red },
    0, -- { suit = data.cardSuit.may,         type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    0, -- { suit = data.cardSuit.may,         type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    40, -- { suit = data.cardSuit.june,        type = data.cardType.animal, symbol = data.cardSymbol.butterfly },
    30, -- { suit = data.cardSuit.june,        type = data.cardType.ribbon, symbol = data.cardSymbol.blue },
    0, -- { suit = data.cardSuit.june,        type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    0, -- { suit = data.cardSuit.june,        type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    40, -- { suit = data.cardSuit.july,        type = data.cardType.animal, symbol = data.cardSymbol.boar },
    10, -- { suit = data.cardSuit.july,        type = data.cardType.ribbon, symbol = data.cardSymbol.red },
    0, -- { suit = data.cardSuit.july,        type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    0, -- { suit = data.cardSuit.july,        type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    70, -- { suit = data.cardSuit.august,      type = data.cardType.bright, symbol = data.cardSymbol.moon },
    20, -- { suit = data.cardSuit.august,      type = data.cardType.animal, symbol = data.cardSymbol.geese },
    5, -- { suit = data.cardSuit.august,      type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    5, -- { suit = data.cardSuit.august,      type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    100, -- { suit = data.cardSuit.september,   type = data.cardType.animal, symbol = data.cardSymbol.sakeCup },
    30, -- { suit = data.cardSuit.september,   type = data.cardType.ribbon, symbol = data.cardSymbol.blue },
    5, -- { suit = data.cardSuit.september,   type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    5, -- { suit = data.cardSuit.september,   type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    40, -- { suit = data.cardSuit.october,     type = data.cardType.animal, symbol = data.cardSymbol.deer },
    30, -- { suit = data.cardSuit.october,     type = data.cardType.ribbon, symbol = data.cardSymbol.blue },
    0, -- { suit = data.cardSuit.october,     type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    0, -- { suit = data.cardSuit.october,     type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    30, -- { suit = data.cardSuit.november,    type = data.cardType.bright, symbol = data.cardSymbol.rainman },
    20, -- { suit = data.cardSuit.november,    type = data.cardType.animal, symbol = data.cardSymbol.swallow },
    10, -- { suit = data.cardSuit.november,    type = data.cardType.ribbon, symbol = data.cardSymbol.red },
    0, -- { suit = data.cardSuit.november,    type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    50, -- { suit = data.cardSuit.december,    type = data.cardType.bright, symbol = data.cardSymbol.phoenix },
    0, -- { suit = data.cardSuit.december,    type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    0, -- { suit = data.cardSuit.december,    type = data.cardType.chaff,  symbol = data.cardSymbol.none },
    0, -- { suit = data.cardSuit.december,    type = data.cardType.chaff,  symbol = data.cardSymbol.none },
}

---@class KoiKoi.WeightedBrain.Params : KoiKoi.IBrain.Params

---@param params KoiKoi.WeightedBrain.Params?
---@return KoiKoi.WeightedBrain
function this.new(params)
    local instance = brain.new(params)
    instance.weights = table.copy(baseWeights)
    ---@cast instance KoiKoi.WeightedBrain
    setmetatable(instance, { __index = this })
    return instance
end

---@param params KoiKoi.IBrain.GenericParams
---@return KoiKoi.WeightedBrain
function this.generate(params)
    return this.new({logger = params.logger})
end

---@param self KoiKoi.WeightedBrain
function this.Reset(self)
    self.weights = table.copy(baseWeights)
end

---@param cardId integer
---@param ground integer[]
---@param weights number[]
---@return integer?
---@return number
local function FindMatchWeighted(cardId, ground, weights)
    local max = nil
    local id = nil
    -- find most weight
    for _, i in ipairs(ground) do
        if koi.CanMatchSuit(cardId, i) then
            local w = weights[i]
            if max == nil or w > max then
                max = w
                id = i
            end
        end
    end
    max = max or 0
    return id, max + weights[cardId]
end

---@param self KoiKoi.WeightedBrain
---@param p KoiKoi.AI.Params
function this.UpdateWeights(self, p)
    -- TODO update weights
end

---@param self KoiKoi.WeightedBrain
---@param p KoiKoi.AI.Params
---@return KoiKoi.MatchCommand?
function this.Simulate(self, p)
    if p.drawnCard then
        local matched = FindMatchWeighted(p.drawnCard, p.groundPool, self.weights)
        self:UpdateWeights(p)
        if matched then
            self.logger:trace(string.format("match drawnCard = %d, matchedCard = %d", p.drawnCard, matched))
            return { selectedCard = p.drawnCard, matchedCard = matched }
        end
        -- discard
        self.logger:trace(string.format("discard drawnCard = %d", p.drawnCard))
        return { selectedCard = p.drawnCard, matchedCard = nil } -- discard
    else
        local max = nil
        local min = nil
        local hand = nil
        local matched = nil
        local discard = nil
        for _, h in ipairs(p.pool.hand) do
            local id, w = FindMatchWeighted(h, p.groundPool, self.weights)
            if id then
                if max == nil or w > max then
                max = w
                matched = id
                hand = h
                end
            else
                if min == nil or w < min then
                    min = w
                    discard = h
                end
            end
        end
        self:UpdateWeights(p)
        if hand and matched then
            self.logger:trace(string.format("match selectedCard = %d, matchedCard = %d", hand, matched))
            return { selectedCard = hand, matchedCard = matched }
        end
        if discard then
            self.logger:trace(string.format("discard selectedCard = %d", discard))
            return { selectedCard = discard, matchedCard = nil } -- discard
        end
    end
    self.logger:trace("no hand, no drawn")
    return { selectedCard = nil, matchedCard = nil } -- skip
end

--and current yaku
---@param self KoiKoi.WeightedBrain
---@param p KoiKoi.AI.Params
---@return KoiKoi.CallCommand?
function this.Call(self, p)

    if table.size(p.pool.hand) == 0 then -- avoid tie
        return { calling = koi.calling.shobu }
    end

    local k = math.random() < 0.3 -- todo
    k = false
    self.logger:trace(k and "koikoi" or "shobu")
    return { calling = k and koi.calling.koikoi or koi.calling.shobu }
end

return this
