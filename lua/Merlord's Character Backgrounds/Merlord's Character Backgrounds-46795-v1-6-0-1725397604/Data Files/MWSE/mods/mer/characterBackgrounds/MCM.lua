local common = require("mer.characterBackgrounds.common")
local config = common.config
local logger = common.createLogger("MCM")
local UI = require("mer.characterBackgrounds.UI")
local Background = require("mer.characterBackgrounds.Background")

local template
local function registerMCM()
    template = mwse.mcm.createTemplate("Merlord's Character Backgrounds")
    local sideBarDefault = (
        "Welcome to Merlord's Character Backgrounds! This mod adds 25 unique " ..
        "character backgrounds that can be selected after character generation. "
    )
    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        component.sidebar:createHyperLink{
            text = "Made by Merlord",
            exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
            postCreate = (
                function(self)
                    self.elements.outerContainer.borderAllSides = self.indent
                    self.elements.outerContainer.alignY = 1.0
                    self.elements.outerContainer.layoutHeightFraction = 1.0
                    self.elements.info.layoutOriginFractionX = 0.5
                end
            ),
        }

    end

    template:saveOnClose(config.configPath, config.mcm)
    local page = template:createSideBarPage("Settings")
    addSideBar(page)

    page:createOnOffButton{
        label = "Enable Character Backgrounds",
        variable = mwse.mcm.createTableVariable{
            id = "enableBackgrounds",
            table = config.mcm
        },
        description = "Turn this mod on or off."
    }

    page:createButton {
        buttonText = "Activate Backgrounds Menu",
        description = "Manually trigger the Character Backgrounds menu. Be warned, activating this on an existing character may have unintended side effects!",
        inGameOnly = true,
        callback = function()
            timer.delayOneFrame(function()
                UI.createPerkMenu()
            end)
        end
    }

    page:createDropdown{
        label = "Logging Level",
        description = "Set the log level.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcm },
        callback = function(self)
            logger:setLogLevel(self.variable.value)
        end
    }

    template:createExclusionsPage{
        label = "Green Pact",
        description = "The Green Pact dictates that a Bosmer may only eat meat-based products. Use this page to configure which ingredients can be consumed.",
        leftListLabel = "Meat (allowed)",
        rightListLabel = "Non-meat (forbidden)",
        variable = mwse.mcm.createTableVariable{
            id = "greenPactAllowed",
            table = config.mcm
        },
        filters = {
            {
                label = "Ingredients",
                type = "Object",
                objectType = tes3.objectType.ingredient
            }
        }
    }

    --local ratKing = page:createCategory("Rat King")
    local ratKing = template:createSideBarPage{
        label = Background.registeredBackgrounds.ratKing.name,
        description = Background.registeredBackgrounds.ratKing:getDescription()
    }
    ratKing:createSlider{
        label = "Time between rat hordes: %s hours",
        description = "The number of hours after a horde of rats has been summoned that they can appear again. ",
        variable = mwse.mcm.createTableVariable{ id = "ratKingInterval", table = config.mcm },
        min = 0,
        max = 20,
        step = 1,
        jump = 1
    }
    ratKing:createSlider{
        label = "Chance to summon: %s%%",
        description = "Chance that a horde of rats will be summoned when combat starts. ",
        variable = mwse.mcm.createTableVariable{ id = "ratKingChance", table = config.mcm },
        min = 1,
        max = 240,
        step = 1,
        jump = 24
    }

    --local inheritance = page:createCategory("Inheritance")
    local inheritance = template:createSideBarPage{
        label =  Background.registeredBackgrounds.inheritance.name,
        description = Background.registeredBackgrounds.inheritance:getDescription()
    }
    inheritance:createSlider{
        label = "Inheritance amount: %s gold",
        description = "How much money you get with the Inheritance background. ",
        min = 1000,
        max = 10000,
        step = 1,
        jump = 1000,
        variable = mwse.mcm.createTableVariable{
            id = "inheritanceAmount",
            table = config.mcm,
        },
    }

    template:register()
end

event.register("modConfigReady", registerMCM)

event.register("initialized", function()
    Background.registerMcmPages(template)
end, { priority = -10000 })