-- Load the required modules
local config = require("omy1.AdjustableSoulGemCapacity.config")

event.register("modConfigReady", function()
    require("omy1.AdjustableSoulGemCapacity.mcm")
end)

-- This function will be called when the game has finished loading
local function onInitialized()
    -- Check if the mod is enabled
    if config.modEnabled then
        -- Get the fSoulGemMult GMST
        local gmst = tes3.findGMST("fSoulGemMult")

        -- Check if the GMST was found
        if gmst then
            -- Modify the GMST's value
            gmst.value = config.fSoulGemMult
        else
            mwse.log("[AdjustableSoulGemCapacity] Error: fSoulGemMult game setting not found.")
        end
    end

    mwse.log("[AdjustableSoulGemCapacity] Initialized.")
end

event.register("initialized", onInitialized)