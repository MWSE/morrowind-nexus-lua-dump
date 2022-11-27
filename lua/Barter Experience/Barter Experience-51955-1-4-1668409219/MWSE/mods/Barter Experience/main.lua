--Mod by Muggins because nothing like this exists yet afaik--

local config

event.register("modConfigReady", function()
    require("Barter Experience.mcm")
	config  = require("Barter Experience.config")
end)

local function onBarterSuccess(e)
    -- Store the value of the trade
    local value = e.value
    -- Give some flat experience for each successful trade.
    tes3.mobilePlayer:exerciseSkill(24, (config.FlatRate / 10))
    -- Check that value isn't 0 to stop the mwse.log spam
    if value == 0 then
        -- Make sure value isn't negative, then give a fraction of total trade value as experience.
        if value < 0 then tes3.mobilePlayer:exerciseSkill(24, value * -1 * (config.ValueRate / 100)) else
        tes3.mobilePlayer:exerciseSkill(24, value * (config.ValueRate / 100))
        end
    end
end

local function onInitialized(e)
    if config.modEnabled then
        event.register("barterOffer", onBarterSuccess, {priority = -99999})
        mwse.log("[Barter Experience]: enabled")
    else
        mwse.log("[Barter Experience]: disabled")
    end
end

event.register("initialized", onInitialized )