local common = require("mer.fishing.common")
local logger = common.createLogger("supplies")
local Interop = require("mer.fishing")
local supplyList = {
    mer_bug_spinner = 1,
    mer_bug_spinner2 = 1,
    mer_silver_lure = 1,
    mer_fishing_net = 1,
    misc_de_fishing_pole = 1,
}

for id, count in pairs(supplyList) do
    logger:debug("Registering fishing supply %s with count %s", id, count)
    Interop.registerFishingSupply({id = id, count = count})
end