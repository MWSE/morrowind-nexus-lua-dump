local this = {}
this.mod = "Restock Filled Soul Gems"
this.version = "1.0"
local summary =
    "Restocking supplies of filled soulgems have been added to a few merchants. "
local config = require("JosephMcKean.restockFilledSoulGems.config").config

local soulGemsClasses = {
    ["battlemage service"] = true,
    ["enchanter service"] = true,
    ["healer service"] = true,
    ["mage service"] = true,
    ["nightblade service"] = true,
    ["priest service"] = true,
    ["sorcerer service"] = true,
    ["trader service"] = true,
    ["sorcerer"] = true
}

local function modConfigReady()
    -- add a nice header 
    local template = mwse.mcm.createTemplate {
        name = this.mod,
        headerImagePath = "textures/jsmk/soulGemsMCMHeader.tga"
    }
    template.onClose = function() config.save() end
    template:register()

    -- INFO PAGE
    local infoPage = template:createPage{label = "Info"}
    infoPage:createInfo({
        text = this.mod .. " v" .. this.version .. "\n" .. summary
    })
    infoPage:createYesNoButton{
        label = "Do you want Restock Filled Soul Gems?",
        variable = mwse.mcm.createTableVariable {
            id = "modEnabled",
            table = config
        }
    }
    --[[infoPage:createSlider{
        label = "The amount of restocking non-filled soul gems: ",
        min = 0,
        max = 30,
        step = 5,
        variable = mwse.mcm.createTableVariable {
            id = "maxUnfilledCount",
            table = config
        }
    }]]
    infoPage:createSlider{
        label = "The amount of restocking filled soul gems: ",
        min = 0,
        max = 30,
        step = 5,
        variable = mwse.mcm.createTableVariable {
            id = "maxFilledCount",
            table = config
        }
    }
    -- set logging level
    infoPage:createDropdown{
        label = "Log Level",
        description = "Set the logging level.",
        options = {
            {label = "DEBUG", value = "DEBUG"},
            {label = "INFO", value = "INFO"},
            {label = "ERROR", value = "ERROR"}, {label = "NONE", value = "NONE"}
        },
        variable = mwse.mcm.createTableVariable {
            id = "logLevel",
            table = config
        },
        -- code that copied over from merlord's mod
        callback = function(self)
            for _, log in ipairs(require(
                                     "JosephMcKean.restockFilledSoulGems.logging").loggers) do
                mwse.log("Setting %s to log level %s", log.name,
                         self.variable.value)
                log:setLogLevel(self.variable.value)
            end
        end
    }
    local function createMerchantList()
        local merchants = {}
        for obj in tes3.iterateObjects(tes3.objectType.npc) do
            if not (obj.baseObject and obj.baseObject.id ~= obj.id) then
                if obj:tradesItemType(tes3.objectType.miscItem) and
                    soulGemsClasses[obj.class and obj.class.id:lower()] then
                    merchants[#merchants + 1] =
                        (obj.baseObject or obj).id:lower()
                end
            end
        end
        table.sort(merchants)
        return merchants
    end
    local function createCreatureList()
        local creatures = {}
        for creature in tes3.iterateObjects(tes3.objectType.creature) do
            if not (creature.baseObject and creature.baseObject.id ~=
                creature.id) then
                if creature.soul > 0 then
                    creatures[#creatures + 1] =
                        (creature.baseObject or creature).id:lower()
                end
            end
        end
        table.sort(creatures)
        return creatures
    end
    template:createExclusionsPage{
        label = "Restock Filled Soul Gems Merchants",
        description = "Move merchants into the left list to allow them to restock filled soul gems.",
        variable = mwse.mcm.createTableVariable {
            id = "soulGemsMerchants",
            table = config
        },
        leftListLabel = "Merchants that restock filled soul gems",
        rightListLabel = "Merchants",
        filters = {{label = "Merchants", callback = createMerchantList}}
    }
    template:createExclusionsPage{
        label = "Souls",
        description = "Move creatures into the left list to allow them to be in filled soul gems." ..
            "\n" .. "\n" ..
            "You'll need to REBOOT the game for the newly added/removed souls to take effect.",
        variable = mwse.mcm.createTableVariable {id = "souls", table = config},
        leftListLabel = "Souls for restock filled soul gems",
        rightListLabel = "Creatures",
        filters = {{label = "Creatures", callback = createCreatureList}}
    }
end
event.register("modConfigReady", modConfigReady)

return this
