local configPath = "character_cultures"

local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = {
        enableCultures = true,
    }
    mwse.saveConfig(configPath, config)
end


local culturesList = require("mtrCultures.culturesList")

local perksMenuID = tes3ui.registerID("perksMenu")
local descriptionID = tes3ui.registerID("perkDescriptionText")
local descriptionHeaderID = tes3ui.registerID("perkDescriptionHeaderText")

local data

local function modReady()
    return (
        config.enableCultures and
        not tes3.menuMode() and
        tes3.player and
        data
    )
end


-------------------------------------------------------------
--UI functions
-------------------------------------------------------------

local ctUID = tes3ui.registerID("CultureNameUI")

local function updateCTStat()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
    if menu then
        local cultureLabel = menu:findChild(ctUID)
        if data and data.currentCulture then
            cultureLabel.text =  culturesList[data.currentCulture].name
        else
            cultureLabel.text = "None"
        end
        menu:updateLayout()
    end
end
event.register("menuEnter", updateCTStat)

local function getDescription(culture)
    if type(culture.description) == "function" then
        return culture.description()
    else
        return culture.description
    end
end

local function createCTTooltip()
    if data.currentCulture then
        local culture = culturesList[data.currentCulture]

        local tooltip = tes3ui.createTooltipMenu()
        local outerBlock = tooltip:createBlock()
        outerBlock.flowDirection = "top_to_bottom"
        outerBlock.paddingTop = 6
        outerBlock.paddingBottom = 12
        outerBlock.paddingLeft = 6
        outerBlock.paddingRight = 6
        outerBlock.width = 450
        outerBlock.autoHeight = true

        local header = outerBlock:createLabel{
            text = culture.name
        }
        header.absolutePosAlignX = 0.5
        header.color = tes3ui.getPalette("header_color")


        local description = outerBlock:createLabel{
            text = getDescription(culture)
        }
        description.autoHeight = true
        description.width = 285
        description.wrapText = true

        tooltip:updateLayout()
    end
end


local function createCTStat(e)

    local headingText = "Culture"

    local GUI_Culture_Stat = tes3ui.registerID("GUI_MenuStat_CharacterCulture_Stat")
    local menu = e.element
    local charBlock = menu:findChild(tes3ui.registerID("MenuStat_level_layout")).parent

    local ctBlock = charBlock:findChild(GUI_Culture_Stat)
    if ctBlock then ctBlock:destroy() end

    ctBlock = charBlock:createBlock({ id = GUI_Culture_Stat})
    ctBlock.widthProportional = 1.0
    ctBlock.autoHeight = true

    local headingLabel = ctBlock:createLabel{ text = headingText}
    headingLabel.color = tes3ui.getPalette("header_color")

    local nameBlock = ctBlock:createBlock()
    nameBlock.paddingLeft = 5
    nameBlock.autoHeight = true
    nameBlock.widthProportional = 1.0

    local nameLabel = nameBlock:createLabel{ id = ctUID,  text = "None" }
    if data and data.currentCulture then
        local name = culturesList[data.currentCulture].name
        nameLabel.text = name
    end
    nameLabel.wrapText = true
    nameLabel.widthProportional = 1
    nameLabel.justifyText = "right"


    headingLabel:register("help", createCTTooltip )
    nameBlock:register("help", createCTTooltip )
    nameLabel:register("help", createCTTooltip )

    menu:updateLayout()
end
event.register("uiActivated", createCTStat, { filter = "MenuStat" })

-----------------------------------------------------------------
local okayButton

local function clickedPerk(culture)
    data.currentCulture = culture.id
    local header = tes3ui.findMenu(perksMenuID):findChild(descriptionHeaderID)
    header.text = culture.name

    local description = tes3ui.findMenu(perksMenuID):findChild(descriptionID)
    description.text = getDescription(culture)
    description:updateLayout()

    if not culturesList[data.currentCulture] then
        return
    end

    if culturesList[data.currentCulture].checkDisabled and culturesList[data.currentCulture].checkDisabled() then
        header.color = tes3ui.getPalette("disabled_color")
        okayButton.widget.state = 2
        okayButton.disabled = true
    else
        header.color = tes3ui.getPalette("header_color")
        okayButton.widget.state = 1
        okayButton.disabled = false
    end

end

local function startCultureWhenChargenFinished()
    if tes3.findGlobal("CharGenState").value == -1 then
        updateCTStat()
        event.unregister("simulate", startCultureWhenChargenFinished)
        if data.currentCulture then
            --if culturesList[data.currentCulture].checkDisabled and culturesList[data.currentCulture].checkDisabled() then return end
            local culture = culturesList[data.currentCulture]
            if culture.doOnce then
                culture.doOnce(data)
            end

            if culture.callback then
                culture.callback(data)
            end
        end
    end
end

local function clickedOkay()
    if data.currentCulture then
        event.unregister("simulate", startCultureWhenChargenFinished)
        event.register("simulate", startCultureWhenChargenFinished)
    end
    tes3ui.findMenu(perksMenuID):destroy()
    tes3ui.leaveMenuMode()
    data.inCTMenu = false
    event.trigger("CharacterCultures:OkayMenuClicked")
end


local function createPerkMenu()
    if not modReady() then return end
    data.currentCulture = data.currentCulture or culturesList.none.id
    local perksMenu = tes3ui.createMenu{id = perksMenuID, fixedFrame = true}
    local outerBlock = perksMenu:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.autoHeight = true
    outerBlock.autoWidth = true

    --HEADING
    local title = outerBlock:createLabel{ id = tes3ui.registerID("perksheading"), text = "Select your culture:" }
    title.absolutePosAlignX = 0.5
    title.borderTop = 4
    title.borderBottom = 4

    local innerBlock = outerBlock:createBlock()
    innerBlock.height = 520
    innerBlock.autoWidth = true
    innerBlock.flowDirection = "left_to_right"

    --PERKS
    local perkListBlock = innerBlock:createVerticalScrollPane{ id = tes3ui.registerID("perkListBlock") }
    perkListBlock.layoutHeightFraction = 1.0
    perkListBlock.minWidth = 250
    perkListBlock.autoWidth = true
    perkListBlock.paddingAllSides = 4
    perkListBlock.borderRight = 6

    local sort_func = function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end

    local sortedList = {}
    for _, culture in pairs(culturesList) do
        table.insert(sortedList, culture)
    end
    table.sort(sortedList, sort_func)

    --Default "No culture" button
    --Rest of the buttons
    local preselectedButton
    for _, culture in pairs(sortedList) do
        local perkButton = perkListBlock:createTextSelect{ id = tes3ui.registerID("perkBlock"), text = culture.name }
        perkButton.autoHeight = true
        perkButton.layoutWidthFraction = 1.0
        perkButton.paddingAllSides = 2
        perkButton.borderAllSides = 2
        if culture.checkDisabled and culture.checkDisabled() then
            perkButton.color = tes3ui.getPalette("disabled_color")
            perkButton.widget.idle = tes3ui.getPalette("disabled_color")
        end
        perkButton:register("mouseClick", function()
            local thisCT = culture
            clickedPerk(thisCT)
        end )

        if data.currentCulture == culture.id then
            preselectedButton = perkButton
        end

    end
    --DESCRIPTION
    do
        local descriptionBlock = innerBlock:createThinBorder()
        descriptionBlock.layoutHeightFraction = 1.0
        descriptionBlock.width = 430
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
        list[ math.random(#list) ]:triggerEvent("mouseClick")
    end)


    --OKAY
    okayButton = buttonBlock:createButton{ id = tes3ui.registerID("perkOkayButton"), text = tes3.findGMST(tes3.gmst.sOK).value }
    okayButton.alignX = 1.0
    okayButton:register("mouseClick", clickedOkay)

    perksMenu:updateLayout()

    tes3ui.enterMenuMode(perksMenuID)

    preselectedButton:triggerEvent("mouseClick")

    data.inCTMenu = true
end
event.register("CharacterCultures:OpenPerksMenu", createPerkMenu)


local charGen
local newGame
local function checkCharGen()
    if charGen.value == 10 then
        newGame = true
    elseif newGame and charGen.value == -1 then
        event.unregister("simulate", checkCharGen)
        if not data.currentCulture then
            timer.start{
                type = timer.simulate,
                duration = 0.55,
                callback = createPerkMenu
            }
        end
    end
end



local function loaded()
    newGame = false

    --prepare data
    tes3.player.data.mtrCultures = tes3.player.data.mtrCultures or {}
    data = tes3.player.data.mtrCultures
    --initialise existing culture
    local culture = culturesList[data.currentCulture]
    if culture and culture.callback then
        culture.callback(data)
    end

    --Check for chargen
    charGen = tes3.findGlobal("CharGenState")
    event.unregister("simulate", checkCharGen)
    event.register("simulate", checkCharGen)
end

event.register("loaded", loaded )

---------------------------------------
---MCM
---------------------------------------


local function registerMCM()
    local sideBarDefault = (
        "Welcome to mtrCultures! This mod adds many character cultures that can be selected after character generation. Mod is... lore-friendlish, I certainly took some liberties in creating it, but there isn't really enough lore to not have to do it for this mod. Some ideas come from later Elder Scrolls games, some are from Project Tamriel or even Elder Kings, some are from fanfiction, and some I made up myself... anyway, happy roleplaying!"
    )

    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        component.sidebar:createHyperLink{
            text = "Made by MTR",
            exec = "start https://www.nexusmods.com/users/88247468?tab=user+files",
			postCreate = (
                function(self)
                    self.elements.outerContainer.borderAllSides = self.indent
                    self.elements.outerContainer.alignY = 1.0
                    self.elements.outerContainer.layoutHeightFraction = 1.0
                    self.elements.info.layoutOriginFractionX = 0.5
                end
            ),
        }

		component.sidebar:createHyperLink{
            text = "Thanks to Merlord for Merlord's Character Backgrounds from which I have borrowed 95% of the code :)",
            exec = "start https://www.nexusmods.com/morrowind/mods/46795",  
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



    local template = mwse.mcm.createTemplate("MTR-Cultures")
    template:saveOnClose(configPath, config)

    local page = template:createSideBarPage("Settings")
    addSideBar(page)

    page:createOnOffButton{
        label = "Enable Character Cultures",
        variable = mwse.mcm.createTableVariable{
            id = "enableCultures",
            table = config
        },
        description = "Turn this mod on or off."
    }

    page:createButton {
        buttonText = "Activate Cultures Menu",
        description = "Manually trigger the Character Cultures menu. Be warned, activating this on an existing character may have unintended side effects!",
        inGameOnly = true,
        callback = function()
            timer.delayOneFrame(function()
                createPerkMenu()
            end)
        end
    }
    template:register()
end

event.register("modConfigReady", registerMCM)