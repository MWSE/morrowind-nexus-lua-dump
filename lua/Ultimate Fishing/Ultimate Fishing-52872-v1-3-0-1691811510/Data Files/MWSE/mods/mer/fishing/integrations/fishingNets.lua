--fishingNets.lua

local Interop = require("mer.fishing")

local fishingNets = {
    { id = "mer_fishing_net" },
    { id = "ab_w_toolfishingnet" },
}
event.register("initialized", function(_)
    for _, data in ipairs(fishingNets) do
        Interop.registerFishingNet(data)
    end
end)