--fetch config file
local confPath = "Equipment_and_Items_Requirements_Overhaul_config"
local config = mwse.loadConfig(confPath)
local configBase = require("Equipment and Items Requirements Overhaul.config")

if not config then
    config = configBase
end

local function registerModConfig()
    local EasyMCM = require("easyMCM.EasyMCM")

    local template = EasyMCM.createTemplate("EIRO - Equipment and Items Requirements Overhaul")
    template:saveOnClose("Equipment_and_Items_Requirements_Overhaul_config", config) -- Save config on closing MCM

    local page = template:createSideBarPage({
        label = "Weapon Skills Modifier",
        description = "Adjust the Modifier for various weapon subtypes."
    })

    local settings = page:createCategory({
        label = "Skill Requirement Modifier:",
        description = "How much do you want to add/substract from the skill requirement?\n",
    })

    local function capitalize(text)
        return text:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest:lower() end)
    end

    -- Iterate over each weapon type and create sliders for each subtype
    for weaponType, subtypes in pairs(config.Skills) do
        local settings = page:createCategory({
            label = capitalize(weaponType) .. " :",
            description = "Adjust modifiers for " .. capitalize(weaponType),
        })

        for subtype, value in pairs(subtypes) do
            settings:createSlider({
                label = capitalize(subtype),
                min = -500,
                max = 500,
                step = 1,
                jump = 5,
                defaultSetting = value,
                variable = EasyMCM.createTableVariable({
                    id = subtype,
                    table = subtypes
                })
            })
        end
    end

    --armor
    local page = template:createSideBarPage({
        label = "Armor Skills Modifier",
        description = "Adjust the Modifier for various armor subtypes."
    })

    local settings = page:createCategory({
        label = "Skill Requirement Modifier:",
        description = "How much do you want to add/substract from the skill requirement?\n",
    })

    -- Iterate over each weapon type and create sliders for each subtype
    for armorType, subtypes in pairs(config.ArmorSkills) do
        local settings = page:createCategory({
            label = capitalize(armorType) .. " :",
            description = "Adjust modifiers for " .. capitalize(armorType),
        })

        for subtype, value in pairs(subtypes) do
            settings:createSlider({
                label = capitalize(subtype),
                min = -500,
                max = 500,
                step = 1,
                jump = 5,
                defaultSetting = value,
                variable = EasyMCM.createTableVariable({
                    id = subtype,
                    table = subtypes
                })
            })
        end
    end

    -- Page for Attribute Multipliers
    local attributePage = template:createSideBarPage({
        label = "Attribute Modifies",
        description = "Adjust the modifiers for various character attributes."
    })

    -- Category for Attribute settings
    local attributeSettings = attributePage:createCategory({
        label = "Attribute Modifiers",
        description = "Set the modifiers for different attributes."
    })

    for attributeName, value in pairs(config.Attributes) do
        attributeSettings:createSlider({
            label = attributeName:gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end),
            min = -500,
            max = 500,
            step = 1,
            jump = 5,
            defaultSetting = value,
            variable = EasyMCM.createTableVariable({
                id = attributeName,
                table = config.Attributes
            })
        })
    end

    -- Page for Other Modifiers
    local otherPage = template:createSideBarPage({
        label = "Other Modifiers",
        description = "Adjust the modifier for various items."
    })

    -- Category for Attribute settings
    local otherSettings = otherPage:createCategory({
        label = "Other Modifiers",
        description = "Set the other modifiers."
    })

    for otherName, value in pairs(config.Other) do
        otherSettings:createSlider({
            label = otherName:gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end),
            min = -500,
            max = 500,
            step = 1,
            jump = 5,
            defaultSetting = value,
            variable = EasyMCM.createTableVariable({
                id = otherName,
                table = config.Other
            })
        })
    end


    EasyMCM.register(template)
end

event.register("modConfigReady", registerModConfig)
