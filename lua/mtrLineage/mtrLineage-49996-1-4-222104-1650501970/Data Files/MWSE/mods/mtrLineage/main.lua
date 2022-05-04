local configPath = "character_lineages"

local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = {
        enableLineages = true,
    }
    mwse.saveConfig(configPath, config)
end


local lineagesList = require("mtrLineage.lineagesList")

local perksMenuID = tes3ui.registerID("perksMenu")
local descriptionID = tes3ui.registerID("perkDescriptionText")
local descriptionHeaderID = tes3ui.registerID("perkDescriptionHeaderText")

local data

local function modReady()
    return (
        config.enableLineages and
        not tes3.menuMode() and
        tes3.player and
        data
    )
end


-------------------------------------------------------------
--UI functions
-------------------------------------------------------------

local lgUID = tes3ui.registerID("LineageNameUI")

local function updateLGStat()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
    if menu then
        local lineageLabel = menu:findChild(lgUID)
        if data and data.currentLineage then
            lineageLabel.text =  lineagesList[data.currentLineage].name
        else
            lineageLabel.text = "None"
        end
        menu:updateLayout()
    end
end
event.register("menuEnter", updateLGStat)

local function getDescription(lineage)
    if type(lineage.description) == "function" then
        return lineage.description()
    else
        return lineage.description
    end
end

local function createLGTooltip()
    if data.currentLineage then
        local lineage = lineagesList[data.currentLineage]

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
            text = lineage.name
        }
        header.absolutePosAlignX = 0.5
        header.color = tes3ui.getPalette("header_color")


        local description = outerBlock:createLabel{
            text = getDescription(lineage)
        }
        description.autoHeight = true
        description.width = 285
        description.wrapText = true

        tooltip:updateLayout()
    end
end


local function createLGStat(e)

    local headingText = "Lineage"

    local GUI_Lineage_Stat = tes3ui.registerID("GUI_MenuStat_CharacterLineage_Stat")
    local menu = e.element
    local charBlock = menu:findChild(tes3ui.registerID("MenuStat_level_layout")).parent

    local lgBlock = charBlock:findChild(GUI_Lineage_Stat)
    if lgBlock then lgBlock:destroy() end

    lgBlock = charBlock:createBlock({ id = GUI_Lineage_Stat})
    lgBlock.widthProportional = 1.0
    lgBlock.autoHeight = true

    local headingLabel = lgBlock:createLabel{ text = headingText}
    headingLabel.color = tes3ui.getPalette("header_color")

    local nameBlock = lgBlock:createBlock()
    nameBlock.paddingLeft = 5
    nameBlock.autoHeight = true
    nameBlock.widthProportional = 1.0

    local nameLabel = nameBlock:createLabel{ id = lgUID,  text = "None" }
    if data and data.currentLineage then
        local name = lineagesList[data.currentLineage].name
        nameLabel.text = name
    end
    nameLabel.wrapText = true
    nameLabel.widthProportional = 1
    nameLabel.justifyText = "right"


    headingLabel:register("help", createLGTooltip )
    nameBlock:register("help", createLGTooltip )
    nameLabel:register("help", createLGTooltip )

    menu:updateLayout()
end
event.register("uiActivated", createLGStat, { filter = "MenuStat" })

-----------------------------------------------------------------
local okayButton

local function clickedPerk(lineage)
    data.currentLineage = lineage.id
    local header = tes3ui.findMenu(perksMenuID):findChild(descriptionHeaderID)
    header.text = lineage.name

    local description = tes3ui.findMenu(perksMenuID):findChild(descriptionID)
    description.text = getDescription(lineage)
    description:updateLayout()

    if not lineagesList[data.currentLineage] then
        return
    end

    if lineagesList[data.currentLineage].checkDisabled and lineagesList[data.currentLineage].checkDisabled() then
        header.color = tes3ui.getPalette("disabled_color")
        okayButton.widget.state = 2
        okayButton.disabled = true
    else
        header.color = tes3ui.getPalette("header_color")
        okayButton.widget.state = 1
        okayButton.disabled = false
    end

end

local function startLineageWhenChargenFinished()
    if tes3.findGlobal("CharGenState").value == -1 then
        updateLGStat()
        event.unregister("simulate", startLineageWhenChargenFinished)
        if data.currentLineage then
            --if lineagesList[data.currentLineage].checkDisabled and lineagesList[data.currentLineage].checkDisabled() then return end
            local lineage = lineagesList[data.currentLineage]
            if lineage.doOnce then
                lineage.doOnce(data)
            end

            if lineage.callback then
                lineage.callback(data)
            end
        end
    end
end

local function clickedOkay()
    if data.currentLineage then
        event.unregister("simulate", startLineageWhenChargenFinished)
        event.register("simulate", startLineageWhenChargenFinished)
    end
    tes3ui.findMenu(perksMenuID):destroy()
    tes3ui.leaveMenuMode()
    data.inLGMenu = false
    event.trigger("CharacterLineages:OkayMenuClicked")
end


local function createPerkMenu()
    if not modReady() then return end
    data.currentLineage = data.currentLineage or lineagesList.none.id
    local perksMenu = tes3ui.createMenu{id = perksMenuID, fixedFrame = true}
    local outerBlock = perksMenu:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.autoHeight = true
    outerBlock.autoWidth = true

    --HEADING
    local title = outerBlock:createLabel{ id = tes3ui.registerID("perksheading"), text = "Select your lineage:" }
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
    for _, lineage in pairs(lineagesList) do
        table.insert(sortedList, lineage)
    end
    table.sort(sortedList, sort_func)

    --Default "No lineage" button
    --Rest of the buttons
    local preselectedButton
    for _, lineage in pairs(sortedList) do
        local perkButton = perkListBlock:createTextSelect{ id = tes3ui.registerID("perkBlock"), text = lineage.name }
        perkButton.autoHeight = true
        perkButton.layoutWidthFraction = 1.0
        perkButton.paddingAllSides = 2
        perkButton.borderAllSides = 2
        if lineage.checkDisabled and lineage.checkDisabled() then
            perkButton.color = tes3ui.getPalette("disabled_color")
            perkButton.widget.idle = tes3ui.getPalette("disabled_color")
        end
        perkButton:register("mouseClick", function()
            local thisLG = lineage
            clickedPerk(thisLG)
        end )

        if data.currentLineage == lineage.id then
            preselectedButton = perkButton
        end

    end
    --DESCRIPTION
    do
        local descriptionBlock = innerBlock:createThinBorder()
        descriptionBlock.layoutHeightFraction = 1.0
        descriptionBlock.width = 350
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

    data.inLGMenu = true
end
event.register("CharacterLineages:OpenPerksMenu", createPerkMenu)


local charGen
local newGame
local function checkCharGen()
    if charGen.value == 10 then
        newGame = true
    elseif newGame and charGen.value == -1 then
        event.unregister("simulate", checkCharGen)
        if not data.currentLineage then
            timer.start{
                type = timer.simulate,
                duration = 0.9,
                callback = createPerkMenu
            }
        end
    end
end



local function loaded()
    newGame = false

    --prepare data
    tes3.player.data.mtrLineages = tes3.player.data.mtrLineages or {}
    data = tes3.player.data.mtrLineages
    --initialise existing lineage
    local lineage = lineagesList[data.currentLineage]
    if lineage and lineage.callback then
        lineage.callback(data)
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
        "Welcome to MTR-Lineages! This mod adds many character lineages that can be selected after character generation. As explained in the book 'Notes of Racial Phylogeny' (ignoring whether the book is correct in first place) children in Elder Scrolls universe are born with racial traits of the mother, but some traces of the father may also be present. This, or any further ancestry, is what this mod lets you to specify in your character sheet while acquiring secondary racial characteristics. If you think that some of the options are too crazy, simply ignore them. Happy roleplaying!"
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



    local template = mwse.mcm.createTemplate("MTR-Lineages")
    template:saveOnClose(configPath, config)

    local page = template:createSideBarPage("Settings")
    addSideBar(page)

    page:createOnOffButton{
        label = "Enable Character Lineages",
        variable = mwse.mcm.createTableVariable{
            id = "enableLineages",
            table = config
        },
        description = "Turn this mod on or off."
    }

    page:createButton {
        buttonText = "Activate Lineages Menu",
        description = "Manually trigger the Character Lineages menu. Be warned, activating this on an existing character may have unintended side effects!",
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