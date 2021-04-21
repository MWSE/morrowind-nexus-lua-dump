local config = require("OperatorJack.EnhancedReflection.config")

local function createGeneralCategory(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Enable Debug Messages",
        description = "If enabled, Morrowind will show all debug messages related to this mod in-game and in the MWSE.log.",
        variable = mwse.mcm.createTableVariable{
            id = "debug",
            table = config
        }
    }

    return category
end

local function createReflectionCategory(page)
    local category = page:createCategory{
        label = "Reflection Settings"
    }

    category:createOnOffButton{
        label = "Reflect Effect Reflects Spell Projectiles",
        description = "If enabled, the reflect effect will reflect spells directly back to their caster.",
        variable = mwse.mcm.createTableVariable{
            id = "reflectReflects",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Shield Effect Reflects Spell Projectiles",
        description = "If enabled, the shield effect will reflect spells.",
        variable = mwse.mcm.createTableVariable{
            id = "fireShieldReflects",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Fire Shield Effect Reflects Fire Spell Projectiles",
        description = "If enabled, the fire shield effect will reflect spells which contain the fire damage effect.",
        variable = mwse.mcm.createTableVariable{
            id = "fireShieldReflects",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Frost Shield Effect Reflects Frost Spell Projectiles",
        description = "If enabled, the frost shield effect will reflect spells which contain the frost damage effect.",
        variable = mwse.mcm.createTableVariable{
            id = "frostShieldReflects",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Lightening Shield Effect Reflects Shock Spell Projectiles",
        description = "If enabled, the lightening shield effect will reflect spells which contain the shock damage effect.",
        variable = mwse.mcm.createTableVariable{
            id = "shockShieldReflects",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Magnitude Based Reflection Chance",
        description = "If enabled, reflection chance will be calculated based on the magnitude of the effect. If disabled, reflection chance is always 100%.",
        variable = mwse.mcm.createTableVariable{
            id = "magnitudeBasedChance",
            table = config
        }
    }

    return category
end

local function createGeneralPage(template)
    local page = template:createSideBarPage{
        label = "General Settings",
        description = "Hover over a setting to learn more about it."
    }

    createGeneralCategory(page)
    createReflectionCategory(page)
end


-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Enhanced Reflection")
template:saveOnClose("Enhanced Reflection", config)

createGeneralPage(template)

mwse.mcm.register(template)