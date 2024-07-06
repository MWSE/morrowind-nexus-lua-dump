local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("MerchantController")
local MerchantManager = require("CraftingFramework.components.MerchantManager")

local containers = {}

local function createRegisterContainerConfig(merchantId, contents)
    return {
        merchantId = merchantId,
        contents = contents,
        enabled = function (e)
            return config.mcm.enabled == true
                and config.mcm.paintSuppliesMerchants[merchantId] == true
        end
    }
end

for merchantId, active in pairs(config.mcm.paintSuppliesMerchants) do
    if active then
        table.insert(containers, createRegisterContainerConfig(merchantId, config.merchantPaintingSupplies))
    end
end

local manager = MerchantManager.new{
    modName = "JoyOfPainting",
    logger = logger,
    containers = containers
}

event.register("JoyOfPainting:McmUpdated", function()
    --Compare list of paintSuppliesMerchants or registeredMerchants and register any missing
    for merchantId, active in pairs(config.mcm.paintSuppliesMerchants) do
        merchantId = string.lower(merchantId)
        if active then
            if not manager.registeredContainers[merchantId] then
                manager:registerMerchantContainer(createRegisterContainerConfig(merchantId, config.merchantPaintingSupplies))
            end
        end
    end
    manager:processMerchantsInActiveCells()
end)
manager:registerEvents()