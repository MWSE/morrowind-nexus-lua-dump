
---@class KoiKoi.AnimationBinding
---@field target tes3uiElement
---@field animation KoiKoi.EasingAnimationVector2f
---@field params any -- custom data
---@field onFinished fun(ab : KoiKoi.AnimationBinding)?
---@field onDestory fun(ab : KoiKoi.AnimationBinding)?
local this = {}

---@param target tes3uiElement
---@param animation KoiKoi.EasingAnimationVector2f
---@param params any user data
---@param onFinished fun(ab : KoiKoi.AnimationBinding)?
---@param onDestory fun(ab : KoiKoi.AnimationBinding)?
---@return KoiKoi.AnimationBinding
function this.new(target, animation, params, onFinished, onDestory)
    ---@type KoiKoi.AnimationBinding
    local instance = {target = target, animation = animation, params = params, onFinished = onFinished, onDestory = onDestory}
    setmetatable(instance, { __index = this })
    return instance
end

---@param self KoiKoi.AnimationBinding
---@param deltaTime number
---@return boolean
function this.Update(self, deltaTime)
    local b, x, y = self.animation:Update(deltaTime)
    if b then
        self.target.positionX = x
        self.target.positionY = y
        self.target:updateLayout()
    end
    if not b and self.onFinished then
        self.onFinished(self)
        self.onFinished = nil
    end
    return b
end

---@param self KoiKoi.AnimationBinding
function this.Destory(self)
    if self.onDestory then
        self.onDestory(self)
        self.onDestory = nil
    end
end

return this
