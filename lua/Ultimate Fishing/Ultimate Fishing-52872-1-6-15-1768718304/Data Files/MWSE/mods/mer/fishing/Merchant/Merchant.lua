local common = require("mer.fishing.common")
local logger = common.createLogger("Merchant")
local config = require("mer.fishing.config")
local TagManager = include("CraftingFramework.components.TagManager")

---@class Fishing.Merchant
local Merchant = {}

---@return table<string, boolean>
function Merchant.getMerchants()
    local merchants = table.copy(config.mcm.fishingMerchants)
    if TagManager then
        table.copy(TagManager.getIds("generalTrader"), merchants)
    end
    return merchants
end

---Check the active status of a merchant
---
--- `true` - active
---
--- `false` - inactive
---
--- `nil` - not registered
---@param id string
---@return boolean|nil
function Merchant.isActive(id)
    return Merchant.getMerchants()[id:lower()]
end

---Set the active status of a merchant]
---@param id string
---@param isActive boolean|nil
function Merchant.setMerchant(id, isActive)
    config.mcm.fishingMerchants[id:lower()] = isActive
end

---Register a merchant with the fishing system
---
---If `active` param is not specified, it will default to true.
---
---If the merchant already exists in the mcm config, it will not be overwritten.
---@param e { merchantId: string, active?: boolean }
function Merchant.register(e)
    if Merchant.getMerchants()[e.merchantId:lower()] == nil then
        if e.active == nil then e.active = true end
        logger:debug("Registering Fishing Merchant %s:%s", e.merchantId, e.active)
        Merchant.setMerchant(e.merchantId, e.active)
    else
        logger:debug("Merchant %s already registered", e.merchantId)
    end
end

---@return MerchantManager.ContainerData
function Merchant.createContainerConfig(merchantId, contents)
    ---@type MerchantManager.ContainerData
    local data = {
        merchantId = merchantId,
        contents = contents,
        enabled = function (e)
            return config.mcm.enabled == true
                and Merchant.isActive(merchantId) == true
        end
    }
    return data
end

return Merchant
