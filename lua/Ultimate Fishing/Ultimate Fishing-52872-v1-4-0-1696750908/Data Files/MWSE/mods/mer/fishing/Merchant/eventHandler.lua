local common = require("mer.fishing.common")
local config = require("mer.fishing.config")
local logger = common.createLogger("MerchantController")
local MerchantManager = require("CraftingFramework.components.MerchantManager")
local Supplies = require("mer.fishing.Merchant.Supplies")

local containers = {}

local function createRegisterContainerConfig(merchantId, contents)
    return {
        merchantId = merchantId,
        contents = contents,
        enabled = function (e)
            return config.mcm.enabled == true
                and config.mcm.fishingMerchants[merchantId] == true
        end
    }
end

for merchantId, active in pairs(config.mcm.fishingMerchants) do
    if active then
        table.insert(containers, createRegisterContainerConfig(merchantId, Supplies.supplyList))
    end
end

local manager = MerchantManager.new{
    modName = "fishing",
    logger = logger,
    containers = containers
}

event.register("Fishing:McmUpdated", function()
    logger:info("MCM updated")
    --Compare list of fishingMerchants or registeredMerchants and register any missing
    for merchantId, active in pairs(config.mcm.fishingMerchants) do
        merchantId = string.lower(merchantId)
        logger:debug("Checking merchant %s", merchantId)
        if active then
            if not manager.registeredContainers[merchantId] then
                logger:info("Registering merchant %s", merchantId)
                manager:registerMerchantContainer(createRegisterContainerConfig(merchantId, Supplies.supplyList))
            end
        end
    end
    logger:debug("Processing merchants in active cells")
    manager:processMerchantsInActiveCells()
end)
manager:registerEvents()