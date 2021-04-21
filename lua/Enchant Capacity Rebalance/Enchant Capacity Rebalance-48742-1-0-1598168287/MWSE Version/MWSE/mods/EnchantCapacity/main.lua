local mod = "Enchant Capacity Rebalance"
local version = "1.0"

local data = require("EnchantCapacity.data")

local function onInitialized()

    -- Iterate through our data table.
    for _, dataObject in ipairs(data.objects) do

        -- Get the corresponding game object.
        local object = tes3.getObject(dataObject.id)

        -- If this object exists in the game, change the enchant capacity to match our table.
        if object then
            object.enchantCapacity = dataObject.enchCap
        end
    end

    mwse.log("[%s %s] Initialized.", mod, version)
end

event.register("initialized", onInitialized)