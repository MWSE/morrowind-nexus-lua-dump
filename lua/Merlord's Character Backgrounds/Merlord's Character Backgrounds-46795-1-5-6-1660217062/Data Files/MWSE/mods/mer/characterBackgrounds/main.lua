local configPath = "character_backgrounds"



local config = mwse.loadConfig(configPath, {
    enableBackgrounds = true,
    exclusions = {},
    greenPactAllowed = {},
    ratKingInterval = 24,
    ratKingChance = 3,
    inheritanceAmount = 2000,
    logLevel = "INFO"
})

local logger = require("logging.logger").new{
    name = "Character Backgrounds",
    logLevel = config.logLevel
}

local backgroundsList = require("mer.characterBackgrounds.backgroundsList")

local perksMenuID = tes3ui.registerID("perksMenu")
local descriptionID = tes3ui.registerID("perkDescriptionText")
local descriptionHeaderID = tes3ui.registerID("perkDescriptionHeaderText")

local data

local function modReady()
    return (
        config.enableBackgrounds and
        not tes3.menuMode() and
        tes3.player and
        data
    )
end


-------------------------------------------------------------
--UI functions
-------------------------------------------------------------

local bgUID = tes3ui.registerID("BackgroundNameUI")

local function updateBGStat()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
    if menu then
        local backgroundLabel = menu:findChild(bgUID)
        if data and data.currentBackground then
            backgroundLabel.text =  backgroundsList[data.currentBackground].name
        else
            backgroundLabel.text = "None"
        end
        menu:updateLayout()
    end
end
event.register("menuEnter", updateBGStat)

local function getDescription(background)
    if type(background.description) == "function" then
        return background.description()
    else
        return background.description
    end
end

local function createBGTooltip()
    if data.currentBackground then
        local background = backgroundsList[data.currentBackground]

        local tooltip = tes3ui.createTooltipMenu()
        local outerBlock = tooltip:createBlock()
        outerBlock.flowDirection = "top_to_bottom"
        outerBlock.paddingTop = 6
        outerBlock.paddingBottom = 12
        outerBlock.paddingLeft = 6
        outerBlock.paddingRight = 6
        outerBlock.width = 400
        outerBlock.autoHeight = true

        local header = outerBlock:createLabel{
            text = background.name
        }
        header.absolutePosAlignX = 0.5
        header.color = tes3ui.getPalette("header_color")


        local description = outerBlock:createLabel{
            text = getDescription(background)
        }
        description.autoHeight = true
        description.width = 285
        description.wrapText = true

        tooltip:updateLayout()
    end
end


local function createBGStat(e)

    local headingText = "Background"

    local GUI_Background_Stat = tes3ui.registerID("GUI_MenuStat_CharacterBackground_Stat")
    local menu = e.element
    local charBlock = menu:findChild(tes3ui.registerID("MenuStat_level_layout")).parent

    local bgBlock = charBlock:findChild(GUI_Background_Stat)
    if bgBlock then bgBlock:destroy() end

    bgBlock = charBlock:createBlock({ id = GUI_Background_Stat})
    bgBlock.widthProportional = 1.0
    bgBlock.autoHeight = true

    local headingLabel = bgBlock:createLabel{ text = headingText}
    headingLabel.color = tes3ui.getPalette("header_color")

    local nameBlock = bgBlock:createBlock()
    nameBlock.paddingLeft = 5
    nameBlock.autoHeight = true
    nameBlock.widthProportional = 1.0

    local nameLabel = nameBlock:createLabel{ id = bgUID,  text = "None" }
    if data and data.currentBackground then
        local name = backgroundsList[data.currentBackground].name
        nameLabel.text = name
    end
    nameLabel.wrapText = true
    nameLabel.widthProportional = 1
    nameLabel.justifyText = "right"


    headingLabel:register("help", createBGTooltip )
    nameBlock:register("help", createBGTooltip )
    nameLabel:register("help", createBGTooltip )

    menu:updateLayout()
end
event.register("uiActivated", createBGStat, { filter = "MenuStat" })

-----------------------------------------------------------------
local okayButton

local function clickedPerk(background)
    data.currentBackground = background.id
    local header = tes3ui.findMenu(perksMenuID):findChild(descriptionHeaderID)
    header.text = background.name

    local description = tes3ui.findMenu(perksMenuID):findChild(descriptionID)
    description.text = getDescription(background)
    description:updateLayout()

    if not backgroundsList[data.currentBackground] then
        return
    end

    if backgroundsList[data.currentBackground].checkDisabled and backgroundsList[data.currentBackground].checkDisabled() then
        header.color = tes3ui.getPalette("disabled_color")
        okayButton.widget.state = 2
        okayButton.disabled = true
    else
        header.color = tes3ui.getPalette("header_color")
        okayButton.widget.state = 1
        okayButton.disabled = false
    end

end

local function startBackgroundWhenChargenFinished()
    if tes3.findGlobal("CharGenState").value == -1 then
        updateBGStat()
        event.unregister("simulate", startBackgroundWhenChargenFinished)
        if data.currentBackground then
            --if backgroundsList[data.currentBackground].checkDisabled and backgroundsList[data.currentBackground].checkDisabled() then return end
            local background = backgroundsList[data.currentBackground]
            if background.doOnce then
                background.doOnce(data)
            end

            if background.callback then
                background.callback(data)
            end
        end
    end
end

local function clickedOkay(perksMenu)
    if data.currentBackground then
        event.unregister("simulate", startBackgroundWhenChargenFinished)
        event.register("simulate", startBackgroundWhenChargenFinished)
    end
    logger:debug("Clicked Okay, closing menu")
    perksMenu:destroy()
    tes3ui.leaveMenuMode()
    data.inBGMenu = false
    event.trigger("CharacterBackgrounds:OkayMenuClicked")
end

local function isTextDisabled(element)
    return element.color[1] == tes3ui.getPalette("disabled_color")[1]
        and element.color[2] == tes3ui.getPalette("disabled_color")[2]
        and element.color[3] == tes3ui.getPalette("disabled_color")[3]
end

local function createPerkMenu()
    if not modReady() then return end
    data.currentBackground = data.currentBackground or backgroundsList.none.id
    local perksMenu = tes3ui.createMenu{id = perksMenuID, fixedFrame = true}
    local outerBlock = perksMenu:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.autoHeight = true
    outerBlock.autoWidth = true

    --HEADING
    local title = outerBlock:createLabel{ id = tes3ui.registerID("perksheading"), text = "Select your background:" }
    title.absolutePosAlignX = 0.5
    title.borderTop = 4
    title.borderBottom = 4

    local innerBlock = outerBlock:createBlock()
    innerBlock.height = 350
    innerBlock.autoWidth = true
    innerBlock.flowDirection = "left_to_right"

    --PERKS
    local perkListBlock = innerBlock:createVerticalScrollPane{ id = tes3ui.registerID("perkListBlock") }
    perkListBlock.layoutHeightFraction = 1.0
    perkListBlock.minWidth = 300
    perkListBlock.autoWidth = true
    perkListBlock.paddingAllSides = 4
    perkListBlock.borderRight = 6

    --Move to an array so it can be sorted
    local sortedList = table.values(backgroundsList, function(a, b) return a.name:lower() < b.name:lower() end)

    --Default "No background" button
    --Rest of the buttons
    local preselectedButton
    for _, background in pairs(sortedList) do
        local perkButton = perkListBlock:createTextSelect{ id = tes3ui.registerID("perkBlock"), text = background.name }
        perkButton.autoHeight = true
        perkButton.layoutWidthFraction = 1.0
        perkButton.paddingAllSides = 2
        perkButton.borderAllSides = 2
        if background.checkDisabled and background.checkDisabled() then
            perkButton.color = tes3ui.getPalette("disabled_color")
            perkButton.widget.idle = tes3ui.getPalette("disabled_color")
        end
        perkButton:register("mouseClick", function()
            local thisBG = background
            clickedPerk(thisBG)
        end )

        if data.currentBackground == background.id then
            preselectedButton = perkButton
        end

    end
    --DESCRIPTION
    do
        local descriptionBlock = innerBlock:createThinBorder()
        descriptionBlock.layoutHeightFraction = 1.0
        descriptionBlock.width = 300
        descriptionBlock.borderRight = 10
        descriptionBlock.flowDirection = "top_to_bottom"
        descriptionBlock.paddingAllSides = 10

        local descriptionHeader = descriptionBlock:createLabel{ id = descriptionHeaderID, text = ""}
        descriptionHeader.color = tes3ui.getPalette("header_color")

        local descriptionText = descriptionBlock:createLabel{id = descriptionID, text = ""}
        descriptionText.wrapText = true
    end

    local buttonBlock = outerBlock:createBlock()
    buttonBlock.flowDirection = "left_to_right"
    buttonBlock.widthProportional = 1.0
    buttonBlock.autoHeight = true
    buttonBlock.childAlignX = 1.0


    --Randomise
    local randomButton = buttonBlock:createButton{ text = "Random"}
    randomButton.alignX = 1.0
    randomButton:register("mouseClick", function()
        local list = perkListBlock:getContentElement().children
        local enabledList = {}
        for _, element in ipairs(list) do
            if not isTextDisabled(element) then
                table.insert(enabledList, element)
            else
                logger:debug("%s is disabled", element.text)
            end
        end
        enabledList[ math.random(#enabledList) ]:triggerEvent("mouseClick")
    end)


    --OKAY
    okayButton = buttonBlock:createButton{ id = tes3ui.registerID("perkOkayButton"), text = tes3.findGMST(tes3.gmst.sOK).value }
    okayButton.alignX = 1.0
    okayButton:register("mouseClick", function()
        clickedOkay(perksMenu)
    end)

    perksMenu:updateLayout()

    tes3ui.enterMenuMode(perksMenuID)

    preselectedButton:triggerEvent("mouseClick")

    data.inBGMenu = true
end
event.register("CharacterBackgrounds:OpenPerksMenu", function()
    logger:debug("Opening perks menu from event")
    createPerkMenu()
end)


local charGen
local newGame
local function checkCharGen()
    if charGen.value == 10 then
        logger:debug("New game, will open perks menu when chargen complete")
        newGame = true
    elseif newGame and charGen.value == -1 then
        logger:debug("Character generation is done")
        event.unregister("simulate", checkCharGen)
        if not data.currentBackground then
            logger:debug("Background selected, opening perks menu in 0.7 seconds")
            timer.start{
                type = timer.simulate,
                duration = 0.7,
                callback = function()
                    logger:debug("Creating Perk Menu from timer")
                    createPerkMenu()
                end
            }
        end
    end
end



local function loaded()
    newGame = false

    --prepare data
    tes3.player.data.merBackgrounds = tes3.player.data.merBackgrounds or {}
    data = tes3.player.data.merBackgrounds
    --initialise existing background
    local background = backgroundsList[data.currentBackground]
    if background and background.callback then
        background.callback(data)
    end

    --Check for chargen
    charGen = tes3.findGlobal("CharGenState")
    event.unregister("simulate", checkCharGen)
    event.register("simulate", checkCharGen)
end

event.register("loaded", loaded )


local meatPatterns = {
    "meat",
    "cuttle",
    "egg",
    "skin",
    "hide",
    "jerky",
    "bone",
    "blood",
    "fish",
    "scales",
    "scrib",
    "shalk",
    "leather",
    "pelt",
    "flesh",
    "brain",
    "_ear",
    "eye",
    "heart",
    "tail",
    "tongue",
    "morsel",
    "_ingcrea"
}
local function initialiseConfig()
    local hasInitialised = table.size(config.greenPactAllowed) > 0
    --[[
        If we haven't made this yet, use the string patterns to
        populate ingredients that are allowed
    ]]

    if not hasInitialised then
        config.greenPactAllowed = config.greenPactAllowed or {}
        for ingredient in tes3.iterateObjects(tes3.objectType.ingredient) do
            for _, pattern in ipairs(meatPatterns) do
                local id = string.lower(ingredient.id)
                if string.find(string.lower(id), pattern) then
                    config.greenPactAllowed[id] = true
                    break
                end
            end
        end
        mwse.saveConfig(configPath, config)
    end
end
event.register("initialized", initialiseConfig)
---------------------------------------
---MCM
---------------------------------------


local function registerMCM()
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



    local template = mwse.mcm.createTemplate("Merlord's Character Backgrounds")
    template:saveOnClose(configPath, config)

    local page = template:createSideBarPage("Settings")
    addSideBar(page)

    page:createOnOffButton{
        label = "Enable Character Backgrounds",
        variable = mwse.mcm.createTableVariable{
            id = "enableBackgrounds",
            table = config
        },
        description = "Turn this mod on or off."
    }

    page:createButton {
        buttonText = "Activate Backgrounds Menu",
        description = "Manually trigger the Character Backgrounds menu. Be warned, activating this on an existing character may have unintended side effects!",
        inGameOnly = true,
        callback = function()
            timer.delayOneFrame(function()
                createPerkMenu()
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
        variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
        callback = function(self)
            logger:setLogLevel(self.variable.value)
        end
    }

    template:createExclusionsPage{
        label = "Artificer",
        description = "The Artificer background blocks the use of spells. Add spells to the whitelist to allow them to be cast. This is intended for compatibility with mods that require casting spells for things like summoning companions. ",
        leftListLabel = "Allowed Spells",
        rightListLabel = "Known Spells",
        variable = mwse.mcm.createTableVariable{
            id = "exclusions",
            table = config
        },
        filters = {
            {
                label = "Spells",
                callback = function()
                    local list = {}
                    if tes3.player then
                        for spell in tes3.iterate(tes3.player.object.spells.iterator) do
                            table.insert(list, spell.name)
                        end
                    end
                    return list
                end
            }
        }
    }

    template:createExclusionsPage{
        label = "Green Pact",
        description = "The Green Pact dictates that a Bosmer may only eat meat-based products. Use this page to configure which ingredients can be consumed.",
        leftListLabel = "Meat (allowed)",
        rightListLabel = "Non-meat (forbidden)",
        variable = mwse.mcm.createTableVariable{
            id = "greenPactAllowed",
            table = config
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
        label = backgroundsList.ratKing.name,
        description = getDescription(backgroundsList.ratKing)
    }
    ratKing:createSlider{
        label = "Time between rat hordes: %s hours",
        description = "The number of hours after a horde of rats has been summoned that they can appear again. ",
        variable = mwse.mcm.createTableVariable{ id = "ratKingInterval", table = config },
        min = 0,
        max = 20,
        step = 1,
        jump = 1
    }
    ratKing:createSlider{
        label = "Chance to summon: %s%%",
        description = "Chance that a horde of rats will be summoned when combat starts. ",
        variable = mwse.mcm.createTableVariable{ id = "ratKingChance", table = config },
        min = 1,
        max = 240,
        step = 1,
        jump = 24
    }

    --local inheritance = page:createCategory("Inheritance")
    local inheritance = template:createSideBarPage{
        label =  backgroundsList.inheritance.name,
        description = getDescription(backgroundsList.inheritance)
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
            table = config,
        },
    }
    template:register()
end

event.register("modConfigReady", registerMCM)