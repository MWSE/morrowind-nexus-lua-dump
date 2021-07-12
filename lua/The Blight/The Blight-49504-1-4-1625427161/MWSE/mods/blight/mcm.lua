local config = require("blight.config")

local function createGeneralCategory(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Enable Debug Mode",
        description = "Use this option to enable debug mode. Enabling debug mode can have a performance impact.",
        variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = config
        }
    }

    category:createSlider{
        label = "Base Blight Transmission Chance",
        description = "The base blight transmission chance. This is used when determining if an actor should acquire the blight disease through the various mechanics introduced in this mod: transmission, blight storms, etc. A higher value represents a higher chance of catching blight.",
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "baseBlightTransmissionChance",
            table = config
        }
    }

    return category
end


local function createTransmissionCategory(page)
    local category = page:createCategory{
        label = "Transmission Settings"
    }

    category:createOnOffButton{
        label = "Enable Active Transmission",
        description = "Use this option to enable the Active Transmmission mechanic.",
        variable = mwse.mcm.createTableVariable{
            id = "enableActiveTransmission",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Passive Transmission",
        description = "Use this option to enable the Passive Transmmission mechanic.",
        variable = mwse.mcm.createTableVariable{
            id = "enablePassiveTransmission",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Blightsorm Transmission",
        description = "Use this option to enable the Blighstorm transmission mechanic.",
        variable = mwse.mcm.createTableVariable{
            id = "enableBlightstormTransmission",
            table = config
        }
    }


    return category
end


local function createProtectiveGearCategory(page)
    local category = page:createCategory{
        label = "Protective Gear Settings"
    }

    category:createOnOffButton{
        label = "Enable Protective Gear",
        description = "Use this option to enable the Protective Gear mechanic.",
        variable = mwse.mcm.createTableVariable{
            id = "enableProtectiveGear",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable NPC Protective Gear Distribution",
        description = "Use this option to enable the automatic distribution of protective gear to NPCs. Only NPCs that do not have an item for a given slot will have the chance to receive protective gear. NPCs will only be checked once. Disabling this mechanic does not remove gear already added by this mechanic.",
        variable = mwse.mcm.createTableVariable{
            id = "enableNpcProtectiveGearDistribution",
            table = config
        }
    }

    return category
end


local function createVisualEffectsCategory(page)
    local category = page:createCategory{
        label = "Visual Effects Settings"
    }

    category:createOnOffButton{
        label = "Enable Blight Decals",
        description = "Use this option to enable the Blight Decal mechanic. This applies visual effects to entities affected by the blight, like the player, NPCs, and flora. If disabling, all decals may not be immediately removed but will be removed after restarting the game.",
        variable = mwse.mcm.createTableVariable{
            id = "enableDecalMapping",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Blight Tooltips",
        description = "Use this option to enable the Blight Tooltip mechanic. This will append '(Blighted)` to entity tooltips if the entity is blighted. Example: Tramma Root (Blighted)",
        variable = mwse.mcm.createTableVariable{
            id = "enableTooltip",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("The Blight")
template:saveOnClose("The-Blight", config)

local page = template:createSideBarPage{
    label = "Settings Sidebar",
    description = "Hover over a setting to learn more about it."
}

createGeneralCategory(page)
createTransmissionCategory(page)
createProtectiveGearCategory(page)
createVisualEffectsCategory(page)

mwse.mcm.register(template)