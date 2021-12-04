local mod = "Helm of Tohan BTBGI Patch"
local version = "1.1.1"

local function onInitialized()
    local object = tes3.getObject("helm_tohan_unique")

    if object then
        object.value = 750
        object.maxCondition = 1000
        object.armorRating = 45
        object.enchantCapacity = 650
    end

    mwse.log("[%s %s] Initialized.", mod, version)
end

event.register("initialized", onInitialized)