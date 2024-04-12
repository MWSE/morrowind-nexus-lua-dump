-- Load the required modules
local config = require("omy1.AdjustableEnchantmentCapacity.config")

event.register("modConfigReady", function()
    require("omy1.AdjustableEnchantmentCapacity.mcm")
end)

local function onInitialized()
    -- Check if the GMST exists
    local gmst = tes3.findGMST("fEnchantmentMult")
    if gmst then
        mwse.log("[AdjustableEnchantmentCapacity] Initial fEnchantmentMult: %s", tostring(gmst.value))
    else
        mwse.log("[AdjustableEnchantmentCapacity] Error: fEnchantmentMult game setting not found.")
        return
    end
   
    -- Set the FEnchantmentMult game setting
    gmst.value = config.FEnchantmentMult

    -- item types you want to modify
    local itemTypes = {tes3.objectType.weapon, tes3.objectType.armor, tes3.objectType.clothing, tes3.objectType.ammo, tes3.objectType.book}
    
    if config.modEnabled then
        -- Iterate through all the objects in the game
        for _, itemType in ipairs(itemTypes) do
            for obj in tes3.iterateObjects(itemType) do
                -- If the object exists in the game and has an enchant capacity, change it to whatever value is selected in mcm
                if obj and obj.enchantCapacity then
                    obj.enchantCapacity = config.enchCap
                end
            end
        end
    end

    mwse.log("[AdjustableEnchantmentCapacity] Initialized.")
end

event.register("initialized", onInitialized)