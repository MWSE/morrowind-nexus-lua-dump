local common = require("mer.fishing.common")
local config = require("mer.fishing.config")
local logger = common.createLogger("MerchantController")
local MerchantManager = require("CraftingFramework.components.MerchantManager")
local Supplies = require("mer.fishing.Merchant.Supplies")
local Merchant = require("mer.fishing.Merchant.Merchant")

---@type MerchantManager.ContainerData[]
local containers = {}
do --initialise containers
    local supplyList = Supplies.getSupplyList()
    for merchantId, isActive in pairs(Merchant.getMerchants()) do
        if isActive == true then
            table.insert(containers, Merchant.createContainerConfig(merchantId, supplyList))
        end
    end
end

local manager = MerchantManager.new{
    modName = "fishing",
    logger = logger,
    containers = containers
}

manager:registerEvents()
---Update the list of registered merchants when the MCM is updated
event.register("Fishing:McmUpdated", function()
    logger:info("MCM updated")
    local supplyList = Supplies.getSupplyList()
    --Register any merchants that were added in the MCM
    for merchantId, isActive in pairs(Merchant.getMerchants()) do
        logger:debug("Checking merchant %s", merchantId)
        merchantId = string.lower(merchantId)
        local isRegistered = manager.registeredContainers[merchantId]
        if isActive and not isRegistered then
            logger:info("Registering merchant %s", merchantId)
            local containerConfig = Merchant.createContainerConfig(merchantId, supplyList)
            manager:registerMerchantContainer(containerConfig)
        end
    end
    logger:debug("Processing merchants in active cells")
    manager:processMerchantsInActiveCells()
end)