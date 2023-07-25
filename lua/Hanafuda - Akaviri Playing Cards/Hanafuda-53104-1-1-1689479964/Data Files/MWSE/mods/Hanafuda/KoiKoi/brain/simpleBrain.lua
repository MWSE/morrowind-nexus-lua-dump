--- baseline AI
---@class KoiKoi.SimpleBrain : KoiKoi.IBrain
local this = {}
local brain = require("Hanafuda.KoiKoi.brain.brain")
setmetatable(this, {__index = brain})

local koi = require("Hanafuda.KoiKoi.koikoi")

---@param params KoiKoi.IBrain.Params?
---@return KoiKoi.SimpleBrain
function this.new(params)
    local instance = brain.new(params)
    ---@cast instance KoiKoi.SimpleBrain
    setmetatable(instance, { __index = this })
    return instance
end

---@param params KoiKoi.IBrain.GenericParams
---@return KoiKoi.SimpleBrain
function this.generate(params)
    return this.new({logger = params.logger})
end

---@param self KoiKoi.SimpleBrain
function this.Reset(self)
    self.timer = 0
    self.wait = nil
end

---@param self KoiKoi.SimpleBrain
---@param p KoiKoi.AI.Params
---@return KoiKoi.MatchCommand?
function this.Simulate(self, p)
    if p.drawnCard then
        for _, id in ipairs(p.groundPool) do
            if koi.CanMatchSuit(p.drawnCard, id) then
                self.logger:trace(string.format("match drawnCard = %d, matchedCard = %d", p.drawnCard, id))
                return { selectedCard = p.drawnCard, matchedCard = id }
            end
        end
        self.logger:trace(string.format("discard drawnCard = %d", p.drawnCard))
        return { selectedCard = p.drawnCard, matchedCard = nil } -- discard
    else
        for _, hand in ipairs(p.pool.hand) do
            for _, id in ipairs(p.groundPool) do
                if koi.CanMatchSuit(hand, id) then
                    self.logger:trace(string.format("match selectedCard = %d, matchedCard = %d", hand, id))
                    return { selectedCard = hand, matchedCard = id }
                end
            end
        end
        if table.size(p.pool.hand) > 0 then
            self.logger:trace(string.format("discard selectedCard = %d", p.pool.hand[1]))
            return { selectedCard = p.pool.hand[1], matchedCard = nil } -- discard
        end
    end
    self.logger:trace("no hand, no drawn")
    return { selectedCard = nil, matchedCard = nil } -- skip
end

--and current yaku
---@param self KoiKoi.SimpleBrain
---@param p KoiKoi.AI.Params
---@return KoiKoi.CallCommand?
function this.Call(self, p)
    self.logger:trace("always shobu")
    return { calling = koi.calling.shobu }
end

return this
