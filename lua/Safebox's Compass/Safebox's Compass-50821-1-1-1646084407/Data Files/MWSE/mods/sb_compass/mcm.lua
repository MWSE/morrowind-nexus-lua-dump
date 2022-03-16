local confPath = "sb_compass"

local colours = {
    red    = { 193 / 255, 63 / 255, 55 / 255 },
    yellow = { 253 / 255, 241 / 255, 172 / 255 },
    green  = { 221 / 255, 255 / 255, 221 / 255 },
    blue   = { 168 / 255, 183 / 255, 234 / 255 },
    indigo = { 184 / 255, 102 / 255, 211 / 255 },
    violet = { 251 / 255, 224 / 255, 254 / 255 },
    white  = { 1, 1, 1 },
    black  = { 0, 0, 0 }
}
local mcm = { config         = mwse.loadConfig(confPath) or
        {
            enabled                = true,
            mrkBackground          = 0,
            midDist                = 12,
            nearDist               = 11,
            mrkSign                = { enabled = true, colour = colours.blue },
            mrkBanner              = { enabled = true, colour = colours.blue },
            mrkTransport           = { enabled = true, colour = colours.yellow },
            mrkSpellsMerchant      = { enabled = true, colour = colours.yellow },
            mrkTrainMerchant       = { enabled = true, colour = colours.yellow },
            mrkSpellmakingMerchant = { enabled = true, colour = colours.yellow },
            mrkEnchantmentMerchant = { enabled = true, colour = colours.yellow },
            mrkRepairMerchant      = { enabled = true, colour = colours.yellow },
            mrkMerchant            = { enabled = true, colour = colours.yellow },
            mrkCompanion           = { enabled = true, colour = colours.green },
            mrkDetectAnimal        = { enabled = true, colour = colours.violet },
            mrkDetectEnchantment   = { enabled = true, colour = colours.violet },
            mrkDetectKey           = { enabled = true, colour = colours.violet }
        },
              compass        = tes3uiElement,
              soonMarkers    = {
                  far  = {},
                  mid  = {},
                  near = {},
                  dyn  = {}
              },

              distMarkers    = {
                  far  = {},
                  mid  = {},
                  near = {},
                  dyn  = {}
              },

              ---@class uiMarkers
              ---@field marker tes3uiElement
              ---@field mini tes3uiElement
              ---@field sub boolean|string|tes3uiElement
              uiMarkers      = {},
              uiRefreshState = 0,
              uiEvents       = {},
              ---@class colours
              colours        = colours,
}

local properties = {
    { "Travel Signposts", mcm.config.mrkSign },
    { "Store Signs", mcm.config.mrkBanner },
    { "Transport and Propylons", mcm.config.mrkTransport },
    { "Merchants selling Spells", mcm.config.mrkSpellsMerchant },
    { "Merchants selling Training", mcm.config.mrkTrainMerchant },
    { "Merchants selling Spellmaking", mcm.config.mrkSpellmakingMerchant },
    { "Merchants selling Enchanting", mcm.config.mrkEnchantmentMerchant },
    { "Merchants selling Repair", mcm.config.mrkRepairMerchant },
    { "Other Merchants", mcm.config.mrkMerchant },
    { "Companions", mcm.config.mrkCompanion },
    { "Detect Animal", mcm.config.mrkDetectAnimal },
    { "Detect Enchantment", mcm.config.mrkDetectEnchantment },
    { "Detect Key", mcm.config.mrkDetectKey }
}

local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "Safebox's Compass" }
    template.onClose = function()
        if (mcm.compass) then
            --local children = multi:findChild("sb_compass").children
            --for _, element in ipairs(children) do
            --    if (element.name ~= "sb_compass_border") then
            --        element:destroy()
            --    end
            --end
            mcm.uiRefreshState = 1
        end
        mwse.saveConfig(confPath, mcm.config)
    end
    --template:saveOnClose(confPath, mcm.config)

    local page = template:createPage { label = "", noScroll = true }
    local elementGroup = page:createSideBySideBlock()

    elementGroup = page:createSideBySideBlock()
    elementGroup:createInfo { text = "Enabled" }
    elementGroup:createOnOffButton {
        variable = mwse.mcm:createTableVariable {
            id    = "enabled",
            table = mcm.config
        }
    }

    elementGroup:createInfo { text = "Marker Style" }
    elementGroup:createDropdown {
        options  = {
            { label = "Morrowind", value = 0 },
            { label = "Skyrim - White", value = 1 },
            { label = "Skyrim - RGB", value = 2 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "mrkBackground",
            table = mcm.config
        }
    }

    page:createSlider {
        label    = "Mid Marker Distance (Default: 2^11 = 2048 units)",
        min      = 5,
        max      = 12,
        step     = 1,
        jump     = 2,
        variable = mwse.mcm:createTableVariable {
            id    = "midDist",
            table = mcm.config
        }
    }

    page:createSlider {
        label    = "Near Marker Distance (Default: 2^10 = 1024 units)",
        min      = 5,
        max      = 12,
        step     = 1,
        jump     = 2,
        variable = mwse.mcm:createTableVariable {
            id    = "nearDist",
            table = mcm.config
        }
    }

    for _, p in ipairs(properties) do
        elementGroup = page:createSideBySideBlock()
        elementGroup:createInfo { text = p[1] }
        elementGroup:createOnOffButton {
            variable = mwse.mcm:createTableVariable {
                id    = "enabled",
                table = p[2]
            }
        }
        elementGroup:createDropdown {
            options  = {
                { label = "Red", value = mcm.colours.red },
                { label = "Yellow", value = mcm.colours.yellow },
                { label = "Green", value = mcm.colours.green },
                { label = "Blue", value = mcm.colours.blue },
                { label = "Indigo", value = mcm.colours.indigo },
                { label = "Violet", value = mcm.colours.violet },
            },
            variable = mwse.mcm:createTableVariable {
                id    = "colour",
                table = p[2]
            }
        }
    end

    mwse.mcm.register(template)
end

function mcm.init()
    event.register("modConfigReady", registerModConfig)
end

return mcm