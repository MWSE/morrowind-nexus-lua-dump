local TagManager = require("CraftingFramework.components.TagManager")

local merchants = {
}

TagManager.registerTag("fishingTrader")
for _, merchantId in ipairs(merchants) do
    TagManager.addId{
        tag = "fishingTrader",
        id = merchantId,
    }
end