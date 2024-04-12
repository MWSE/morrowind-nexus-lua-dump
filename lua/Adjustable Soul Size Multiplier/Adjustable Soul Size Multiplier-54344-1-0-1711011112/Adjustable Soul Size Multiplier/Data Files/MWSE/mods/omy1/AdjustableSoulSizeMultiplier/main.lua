-- Load the required modules
local config = require("omy1.AdjustableSoulSizeMultiplier.config")

event.register("modConfigReady", function()
    require("omy1.AdjustableSoulSizeMultiplier.mcm")
end)

local function modifySoulSize()
    -- Iterate over all creatures in the game
    for creature in tes3.iterateObjects(tes3.objectType.creature) do
        -- Check if the creature has a soul value
        if creature.soul then
                 -- Modify the soul size here based on your configuration multiplier
                 creature.soul = creature.soul * config.soulSizeMultiplier
                end
            end
    mwse.log("[AdjustableSoulSizeMultiplier] All creature soul sizes updated.")
end

-- Register the modifySoulSize function to be called when the mod is initialized
event.register("initialized", modifySoulSize)