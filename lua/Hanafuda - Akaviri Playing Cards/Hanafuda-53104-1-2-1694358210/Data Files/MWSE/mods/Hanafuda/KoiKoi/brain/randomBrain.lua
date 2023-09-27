--- randomness AI
---@class KoiKoi.RandomBrain : KoiKoi.IBrain
---@field koikoiChance number
---@field meaninglessDiscardChance number
---@field waitHand KoiKoi.AI.WaitRange?
---@field waitDrawn KoiKoi.AI.WaitRange?
---@field waitCalling KoiKoi.AI.WaitRange?
---@field timer number
---@field wait number?
local this = {}
local brain = require("Hanafuda.KoiKoi.brain.brain")
setmetatable(this, {__index = brain})

local koi = require("Hanafuda.KoiKoi.koikoi")

---@class KoiKoi.RandomBrain.Params : KoiKoi.IBrain.Params
---@field koikoiChance number?
---@field meaninglessDiscardChance number?
---@field waitHand KoiKoi.AI.WaitRange?
---@field waitDrawn KoiKoi.AI.WaitRange?
---@field waitCalling KoiKoi.AI.WaitRange?

local defaults = {
    koikoiChance = 0.3,
    meaninglessDiscardChance = 0,
    timer = 0,
}

---@param params KoiKoi.RandomBrain.Params?
---@return KoiKoi.RandomBrain
function this.new(params)
    local instance = brain.new(params)
    table.copymissing(instance, defaults)
    ---@cast instance KoiKoi.RandomBrain
    instance.logger:debug("discardChance %f, koikoiChance %f", instance.meaninglessDiscardChance, instance.koikoiChance)
    setmetatable(instance, { __index = this })
    return instance
end

---@param params KoiKoi.IBrain.GenericParams
---@return KoiKoi.RandomBrain
function this.generate(params)
    return this.new({
        logger = params.logger,
        koikoiChance = params.numbers[1],
        meaninglessDiscardChance = params.numbers[2],
    })
end

---@param self KoiKoi.RandomBrain
function this.Reset(self)
    self.timer = 0
    self.wait = nil
end

---comment
---@param cardId integer
---@param ground integer[]
---@return integer[]
local function Match(cardId, ground)
    local matched = {} ---@type integer[]
    for _, id in ipairs(ground) do
        if koi.CanMatchSuit(cardId, id) then
            table.insert(matched, id)
        end
    end
    return matched
end

---@param self KoiKoi.RandomBrain
---@param waitRange KoiKoi.AI.WaitRange?
---@param deltaTime number
---@return boolean
function this.Wait(self, waitRange, deltaTime)
    local w = waitRange
    if w then
        if self.wait == nil then
            self.timer = 0
            self.wait = math.random() * (w.e - w.s) + w.s
            self.logger:trace(string.format("wait for %f seconds", self.wait))
        end
        if self.timer < self.wait then
            self.timer = self.timer + deltaTime
            return true -- feigning thinking
        end
    end
    return false
end

---@param self KoiKoi.RandomBrain
---@param p KoiKoi.AI.Params
---@return KoiKoi.MatchCommand?
function this.Simulate(self, p)
    if p.drawnCard then
        if self:Wait(self.waitDrawn, p.deltaTime) then
            return nil
        end

        local matched = Match(p.drawnCard, p.groundPool)
        if table.size(matched) > 0 then
            local id = matched[math.random(1, table.size(matched))]
            self.logger:trace(string.format("match drawnCard = %d, matchedCard = %d", p.drawnCard, id))
            self.wait = nil
            return { selectedCard = p.drawnCard, matchedCard = id }
        end
        -- discard
        self.logger:trace(string.format("discard drawnCard = %d", p.drawnCard))
        self.wait = nil
        return { selectedCard = p.drawnCard, matchedCard = nil } -- discard
    else
        if self:Wait(self.waitHand, p.deltaTime) then
            return nil
        end

        local hands = {} ---@type integer[]
        local allMatches = {} ---@type integer[][]
        local discardable = {} ---@type integer[]
        for _, hand in ipairs(p.pool.hand) do
            local matched = Match(hand, p.groundPool)
            if table.size(matched) > 0 then
                table.insert(hands, hand)
                table.insert(allMatches, matched)
            else
                table.insert(discardable, hand)
            end
        end
        if self.meaninglessDiscardChance > 0 and self.meaninglessDiscardChance > math.random() then
            -- try meaningless discard
            if table.size(discardable) > 0 then
                local id = discardable[math.random(1, table.size(discardable))]
                self.logger:trace(string.format("meaningless discard selectedCard = %d", id))
                self.wait = nil
                return { selectedCard = id, matchedCard = nil } -- discard
            end
        end
        if table.size(hands) > 0 then
            local index = math.random(1, table.size(hands))
            local hand = hands[index]
            local matched = allMatches[index]
            local id = matched[math.random(1, table.size(matched))]
            self.logger:trace(string.format("match selectedCard = %d, matchedCard = %d", hand, id))
            self.wait = nil
            return { selectedCard = hand, matchedCard = id }
        end

        -- discard
        if table.size(p.pool.hand) > 0 then
            local id = p.pool.hand[math.random(1, table.size(p.pool.hand))]
            self.logger:trace(string.format("discard selectedCard = %d", id))
            self.wait = nil
            return { selectedCard = id, matchedCard = nil } -- discard
        end
    end
    self.logger:trace("no hand, no drawn")
    self.wait = nil
    return { selectedCard = nil, matchedCard = nil } -- skip
end

--and current yaku
---@param self KoiKoi.RandomBrain
---@param p KoiKoi.AI.Params
---@return KoiKoi.CallCommand?
function this.Call(self, p)
    if self:Wait(self.waitCalling, p.deltaTime) then
        return nil
    end

    if table.size(p.pool.hand) == 0 then -- avoid tie
        return { calling = koi.calling.shobu }
    end

    local k = math.random() < self.koikoiChance
    self.logger:trace(k and "koikoi" or "shobu")
    return { calling = k and koi.calling.koikoi or koi.calling.shobu }
end

return this
