local base = require("InspectIt.controller.base")

---@class Renderer : IController
---@field pauseRenderingInMenus boolean
local this = {}
setmetatable(this, { __index = base })

---@type Renderer
local defaults = {
    pauseRenderingInMenus = true,
}

---@return Renderer
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Renderer

    instance.logger:debug("Initial pauseRenderingInMenus: %s", tostring(mge.render.pauseRenderingInMenus))
    instance.pauseRenderingInMenus = mge.render.pauseRenderingInMenus

    return instance
end

---@param self Renderer
---@param params Activate.Params
function this.Activate(self, params)
    self.logger:debug("[Activate] pauseRenderingInMenus: %s", tostring(mge.render.pauseRenderingInMenus))
    self.pauseRenderingInMenus = mge.render.pauseRenderingInMenus
    mge.render.pauseRenderingInMenus = false
end

---@param self Renderer
---@param params Deactivate.Params
function this.Deactivate(self, params)
    -- Inconsistency if switched from options when enabled
    self.logger:debug("[Deactivate] pauseRenderingInMenus: %s", tostring(mge.render.pauseRenderingInMenus))
    mge.render.pauseRenderingInMenus = self.pauseRenderingInMenus
end

---@param self Renderer
function this.Reset(self)
end

return this
