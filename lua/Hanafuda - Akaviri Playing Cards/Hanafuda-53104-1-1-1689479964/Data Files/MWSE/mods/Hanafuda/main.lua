local config = require("Hanafuda.config")

---@param _ initializedEventData
local function OnInitialized(_)
    if config.development.debug then
        require("Hanafuda.KoiKoi.MWSE.debug")
        require("Hanafuda.Gamble.debug")
    end

    require("Hanafuda.Gamble.service")

end
event.register(tes3.event.initialized, OnInitialized)

require("Hanafuda.mcm")

-- unittest
if config.development.unittest then
    require("Hanafuda.test")
    require("Hanafuda.KoiKoi.MWSE.test")
    require("Hanafuda.Gamble.test")
end

--- Since the annotation are not defined in MWSE, this is to supress the warning caused by this.
--- @class tes3scriptVariables
