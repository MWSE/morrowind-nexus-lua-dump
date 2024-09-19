---@class ShopAround.Config
local config = {}

config.metadata = toml.loadFile("Data Files\\Shop Around-metadata.toml") --[[@as MWSE.Metadata]]

config.static = {
    vanillaIndicatorPath = "textures\\target.dds",
    defaultIndicatorPath = "textures\\mer_shopAround\\mer_ind_default.dds",
    stealIndicatorPath = "textures\\mer_shopAround\\mer_ind_hand.dds",
    modIndicatorBlocks = {
        "EssentialIndicators_block",
        "OwnershipIndicator_block",
    }
}

---@class ShopAround.Config.MCM
local mcmDefault = {
    ---If true, the player can purchase an item by activating it directly
    enableDirectPurchase = true,
    ---The log level for the mod. One of "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"
    logLevel = "INFO",
}

---@type ShopAround.Config.MCM
config.mcm = mwse.loadConfig(config.metadata.package.name, mcmDefault)

config.save = function()
    mwse.saveConfig(config.metadata.package.name, config.mcm)
end

return config