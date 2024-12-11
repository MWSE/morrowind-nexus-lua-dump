local Interop = require("mer.fishing")

---@type Fishing.FishingRod.config[]
local fishingRods = {
    {
        id = "mer_fishing_pole_01",
        quality = 0.25
    },
}

event.register("initialized", function (e)
    for _, data in ipairs(fishingRods) do
        Interop.registerFishingRod(data)
    end
end)

