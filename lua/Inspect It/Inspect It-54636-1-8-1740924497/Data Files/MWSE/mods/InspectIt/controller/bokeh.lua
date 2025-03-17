local base = require("InspectIt.controller.base")
local config = require("InspectIt.config").display
local unit2m = 1.0 / 70.0 -- 1units/70meters

---@class Bokeh : IController
---@field shader mgeShaderHandle?
---@field focalLength number
local this = {}
setmetatable(this, { __index = base })

---@type Bokeh
local defaults = {
    focalLength = 1,
}

local fx = "InspectIt/Bokeh"
local disabledShaders = { "Depth of Field" }

---@return Bokeh
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Bokeh

    return instance
end

---@param self Bokeh
---@param value number
function this.SetFocalLength(self, value)
    self.focalLength = math.clamp(value, 0, 2)
    self.shader["focal_length"] = self.focalLength
end

---@param self Bokeh
---@param params Activate.Params
function this.Activate(self, params)
    if not config.bokeh then
        return
    end
    if not self.shader then
        self.shader = mge.shaders.load({ name = fx })
        if self.shader then
            self.logger:info("Loaded shader: %s", fx)
        else
            self.logger:error("Failed to load shader: %s", fx)
        end
    end
    if self.shader then
        self.shader.enabled = true
        self.shader["focus_distance"] = params.offset * unit2m
        self:SetFocalLength(1.0)
    end
end

---@param self Bokeh
---@param params Deactivate.Params
function this.Deactivate(self, params)
    if self.shader then
        self.shader.enabled = false
    end
end

---@param self Bokeh
function this.Reset(self)
end

return this
