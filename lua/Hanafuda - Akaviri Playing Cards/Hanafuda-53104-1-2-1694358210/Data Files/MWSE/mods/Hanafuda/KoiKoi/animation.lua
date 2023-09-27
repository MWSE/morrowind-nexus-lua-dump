---@param t number [0,1]
---@return number [0,1]
local function EaseOutQuad(t)
    local ix = 1.0 - t
    return 1.0 - ix * ix
end

---@param t number [0,1]
---@return number [0,1]
local function EaseOutCubic(t)
    local ix = 1.0 - t
    ix = ix * ix * ix
    return 1.0 - ix
end

---@param t number [0,1]
---@return number [0,1]
local function EaseOutQuart(t)
    local ix = 1.0 - t
    ix = ix * ix
    ix = ix * ix
    return 1.0 - ix
end

--- simple easing animation, less table
---@class KoiKoi.EasingAnimationVector2f
local defaults = {
    startX = 0.0,
    startY = 0.0,
    endX = 0.0,
    endY = 0.0,
    duration = 1.0,
    time = 0.0,
    easing = EaseOutCubic, ---@type fun(t : number) : number
}

---@class KoiKoi.EasingAnimationVector2f
local this = {}

---@param params KoiKoi.EasingAnimationVector2f?
---@return KoiKoi.EasingAnimationVector2f
function this.new(params)
    ---@type KoiKoi.EasingAnimationVector2f
    local instance = table.copy(params) or {}
    table.copymissing(instance, defaults)
    assert(instance.duration > 0)
    instance.easing = instance.easing or EaseOutCubic
    setmetatable(instance, { __index = this })
    return instance
end

---@param self KoiKoi.EasingAnimationVector2f
---@return boolean
function this.IsEnd(self)
    return self.time > self.duration
end

---@param self KoiKoi.EasingAnimationVector2f
---@param deltaTime number
---@return boolean
---@return number
---@return number
function this.Update(self, deltaTime)
    if self:IsEnd() then
        return false, self.endX, self.endY
    end
    self.time = self.time + deltaTime
    assert(self.duration > 0)
    local r = self.time / self.duration
    -- repeat?
    r = math.clamp(r, 0.0, 1.0)
    local t = self.easing(r)
    local x = math.remap(t, 0.0, 1.0, self.startX, self.endX)
    local y = math.remap(t, 0.0, 1.0, self.startY, self.endY)
    return not self:IsEnd(), x, y
end

return this
