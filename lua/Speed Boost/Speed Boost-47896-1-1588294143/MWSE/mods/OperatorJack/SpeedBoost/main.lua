local config = require("OperatorJack.SpeedBoost.config")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("OperatorJack.SpeedBoost.mcm")
end)

local function onCalcMoveSpeed(e)
    e.speed = e.speed * (config.modifier / 100.0)
end
event.register("calcMoveSpeed", onCalcMoveSpeed)