local base = require("InspectIt.controller.base")

---@class MenuMode : IController
---@field entered boolean
local this = {}
setmetatable(this, { __index = base })

---@type MenuMode
local defaults = {
    entered = false,
}

---@return MenuMode
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance MenuMode
    return instance
end

---@param self MenuMode
---@param params Activate.Params
function this.Activate(self, params)
    -- or counter is better
    if not self.entered then
        if not tes3ui.menuMode() then
            self.logger:debug("[Activate] enterMenuMode")
            tes3ui.enterMenuMode("InspectIt")
            self.entered = true
        end
    else
        self.logger:error("[Activate] Previous deactivation is not successful?")
    end
end

---@param self MenuMode
---@param params Deactivate.Params
function this.Deactivate(self, params)
    if self.entered then
        self.entered = false
        tes3ui.leaveMenuMode()
        self.logger:debug("[Deactivate] leaveMenuMode")
    end
end

---@param self MenuMode
function this.Reset(self)
    self.entered = false
end

return this
