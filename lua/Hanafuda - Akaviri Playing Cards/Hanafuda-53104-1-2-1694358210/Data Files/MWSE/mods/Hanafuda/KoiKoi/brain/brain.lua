---@class KoiKoi.ICommand
---@field Execute fun(self) -- todo

---@class KoiKoi.MatchCommand : KoiKoi.ICommand
---@field selectedCard integer
---@field matchedCard integer? if nil means discard

---@class KoiKoi.CallCommand : KoiKoi.ICommand
---@field calling KoiKoi.Calling

---@class KoiKoi.AI.Params
---@field deltaTime number
---@field timestamp number
---@field drawnCard integer? if it is not nil, you must use this.
---@field pool KoiKoi.PlayerPool your card pools
---@field opponentPool KoiKoi.PlayerPool eval for scoreing combinations, but peeping hand is cheating
---@field groundPool  integer[] placed card pools
---@field deck integer[] for cheating
---@field combination { [KoiKoi.CombinationType] : integer }?

---@class KoiKoi.AI.WaitRange
---@field s number start
---@field e number end

---@class KoiKoi.IBrain
---@field logger mwseLogger
local this = {}

---@class KoiKoi.IBrain.Params
---@field logger mwseLogger?

---@class KoiKoi.IBrain.GenericParams : KoiKoi.IBrain.Params
---@field numbers number[]

---@param params KoiKoi.IBrain.Params?
---@return KoiKoi.IBrain
function this.new(params)
    ---@type KoiKoi.IBrain
    local instance = params and table.copy(params) or {}
    instance.logger = instance.logger or require("Hanafuda.logger")
    setmetatable(instance, { __index = this })
    return instance
end

--- reset state
---@param self KoiKoi.IBrain
function this.Reset(self)
    self.logger:trace("IBrain:Reset")
end

--- simulate on every frame
---@param self KoiKoi.IBrain
---@param p KoiKoi.AI.Params
---@return KoiKoi.MatchCommand?
function this.Simulate(self, p)
    self.logger:trace("IBrain:Simulate")
end

--- Call koikoi or shobu
---@param self KoiKoi.IBrain
---@param p KoiKoi.AI.Params
---@return KoiKoi.CallCommand?
function this.Call(self, p)
    self.logger:trace("IBrain:Call")
end

return this
