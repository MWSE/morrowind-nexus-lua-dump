if (mwse.buildDate == nil) or (mwse.buildDate < 20181211) then
    local function warning()
        tes3.messageBox(
            "[Realistic Movement Speeds ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

local config = require("OperatorJack.RealisticMovementSpeeds.config")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("OperatorJack.RealisticMovementSpeeds.mcm")
end)


local function onCalcMoveSpeed(e)
    if e.mobile.isMovingBack then
        local multiplier = config.backwardsMovementMultiplier / 100
        e.speed = e.speed * multiplier
    elseif e.mobile.isMovingLeft or e.mobile.isMovingRight then
        local multiplier = config.strafingMovementMultiplier / 100
        e.speed = e.speed * multiplier
    end
end

local function initialized()
    event.register("calcMoveSpeed", onCalcMoveSpeed)

	print("[Realistic Movement Speeds: INFO] Initialized Realistic Movement Speeds")
end
event.register("initialized", initialized)