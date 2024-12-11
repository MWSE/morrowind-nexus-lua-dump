local common = require("mer.characterBackgrounds.common")
local config = common.config
local logger = common.createLogger("UI")

local bgUID = "BackgroundNameUI"
local perksMenuID = "perksMenu"
local descriptionID = "perkDescriptionText"
local descriptionHeaderID = "perkDescriptionHeaderText"

local Background = require("mer.characterBackgrounds.Background")

---@class CharacterBackgrounds.UI
local UI = {}


local function updateBGStat()
    local menu = tes3ui.findMenu("MenuStat")
    if menu then
        local backgroundLabel = menu:findChild(bgUID)
        if config.persistent.currentBackground then
            backgroundLabel.text =  Background.getCurrentBackground().name
        else
            backgroundLabel.text = "Нет"
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
    if config.persistent.currentBackground then
        local background = Background.getCurrentBackground()

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

    local headingText = "Предыстория"

    local GUI_Background_Stat = "GUI_MenuStat_CharacterBackground_Stat"
    local menu = e.element
    local charBlock = menu:findChild("MenuStat_level_layout").parent

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

    local nameLabel = nameBlock:createLabel{ id = bgUID,  text = "Нет" }
    if config.persistent.currentBackground then
        local name = Background.getCurrentBackground().name
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
    config.persistent.currentBackground = background.id
    local header = tes3ui.findMenu(perksMenuID):findChild(descriptionHeaderID)
    header.text = background.name

    local description = tes3ui.findMenu(perksMenuID):findChild(descriptionID)
    description.text = getDescription(background)
    description:updateLayout()

    local currentBackground = Background.getCurrentBackground()
    if not currentBackground then
        return
    end

    if currentBackground.checkDisabled and currentBackground.checkDisabled() then
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
        logger:debug("Chargen finished, starting background")
        config.persistent.chargenFinished = true
        updateBGStat()
        event.unregister("simulate", startBackgroundWhenChargenFinished)
        local background = Background.getCurrentBackground()
        if background then
            --init default data
            if background.defaultData then
                table.copymissing(background.data, background.defaultData)
            end
            if background.doOnce then
                background:doOnce()
            end
            if background.onLoad then
                background:onLoad()
            end
            ---@diagnostic disable-next-line: deprecated
            if background.callback then background.callback(config.persistent) end
        end
    end
end

local function clickedOkay(perksMenu)
    if config.persistent.currentBackground then
        event.unregister("simulate", startBackgroundWhenChargenFinished)
        event.register("simulate", startBackgroundWhenChargenFinished)
    end
    logger:debug("Clicked Okay, closing menu")
    perksMenu:destroy()
    tes3ui.leaveMenuMode()
    config.persistent.inBGMenu = false
    event.trigger("CharacterBackgrounds:OkayMenuClicked")
end

local function isTextDisabled(element)
    return element.color[1] == tes3ui.getPalette("disabled_color")[1]
        and element.color[2] == tes3ui.getPalette("disabled_color")[2]
        and element.color[3] == tes3ui.getPalette("disabled_color")[3]
end


---@class CharacterBackgrounds.UI.createPerkMenu.params
---@field okCallback function

function UI.createPerkMenu(e)
    if not tes3.player then
        logger:error("No player, can't create perk menu")
        return
    end

    config.persistent.currentBackground = config.persistent.currentBackground or "none"
    local perksMenu = tes3ui.createMenu{id = perksMenuID, fixedFrame = true}
    local outerBlock = perksMenu:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.autoHeight = true
    outerBlock.autoWidth = true

    --HEADING
    local title = outerBlock:createLabel{ id = "perksheading", text = "Выберите предысторию персонажа:" }
    title.absolutePosAlignX = 0.5
    title.borderTop = 4
    title.borderBottom = 4

    local innerBlock = outerBlock:createBlock{ id = "perkInnerBlock" }
    innerBlock.height = 350
    innerBlock.autoWidth = true
    innerBlock.flowDirection = "left_to_right"

    --PERKS
    local perkListBlock = innerBlock:createVerticalScrollPane{ id = "perkListBlock" }
    perkListBlock.widthProportional = 1.0
    perkListBlock.minWidth = 300
    perkListBlock.maxWidth = 300
    perkListBlock.paddingAllSides = 4
    perkListBlock.borderRight = 6

    --Move to an array so it can be sorted
    local sortedList = table.values(Background.registeredBackgrounds, function(a, b) return a.name:lower() < b.name:lower() end)

    --Default "No background" button
    --Rest of the buttons
    local preselectedButton
    for _, background in pairs(sortedList) do
        local perkButton = perkListBlock:createTextSelect{ id = "perkBlock", text = background.name }
        perkButton.autoHeight = true
        perkButton.widthProportional = 1.0
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

        if config.persistent.currentBackground == background.id then
            preselectedButton = perkButton
        end

    end
    --DESCRIPTION
    do
        local descriptionBlock = innerBlock:createThinBorder{ id = "descriptionBlock" }
        descriptionBlock.minWidth = 300
        descriptionBlock.autoWidth = true
        descriptionBlock.heightProportional = 1.0
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
    local randomButton = buttonBlock:createButton{ text = "Случайная"}
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
    okayButton = buttonBlock:createButton{ id = "perkOkayButton", text = tes3.findGMST(tes3.gmst.sOK).value }
    okayButton:register("mouseClick", function()
        clickedOkay(perksMenu)
        if e.okCallback then
            e.okCallback({
                background = Background.getCurrentBackground()
            })
        end
    end)

    perksMenu:updateLayout()

    tes3ui.enterMenuMode(perksMenuID)

    preselectedButton:triggerEvent("mouseClick")

    config.persistent.inBGMenu = true
end

return UI