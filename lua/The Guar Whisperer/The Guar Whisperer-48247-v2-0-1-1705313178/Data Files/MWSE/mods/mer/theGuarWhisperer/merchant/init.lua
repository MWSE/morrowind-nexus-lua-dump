local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Merchant")
local config = common.config
local CraftingFramework = require("CraftingFramework")

local supplies = {
    mer_tgw_flute = -1,
    mer_tgw_guarpack = -1,
    mer_tgw_ball = -3
}

local containers = {}

local function createRegisterContainerConfig(merchantId, contents)
    return {
        merchantId = merchantId,
        contents = contents,
        enabled = function (e)
            return config.mcm.enabled == true
                and config.mcm.merchants[merchantId] == true
        end
    }
end

for merchantId, active in pairs(config.mcm.merchants) do
    if active then
        table.insert(containers, createRegisterContainerConfig(merchantId, supplies))
    end
end

local manager = CraftingFramework.MerchantManager.new{
    modName = "GuarWhisperer",
    logger = logger,
    containers = containers
}

event.register("GuarWhisperer:McmUpdated", function()
    --Compare list of paintSuppliesMerchants or registeredMerchants and register any missing
    for merchantId, active in pairs(config.mcm.merchants) do
        merchantId = string.lower(merchantId)
        if active then
            if not manager.registeredContainers[merchantId] then
                manager:registerMerchantContainer(createRegisterContainerConfig(merchantId, supplies))
            end
        end
    end
    manager:processMerchantsInActiveCells()
end)
manager:registerEvents()