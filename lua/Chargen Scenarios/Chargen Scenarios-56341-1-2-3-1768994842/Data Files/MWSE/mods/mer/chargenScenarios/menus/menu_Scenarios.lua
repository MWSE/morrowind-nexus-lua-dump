
local ChargenMenu = require("mer.chargenScenarios.component.ChargenMenu")
local Menu = require("mer.chargenScenarios.util.Menu")
local Scenario = require("mer.chargenScenarios.component.Scenario")
local Loadouts = require("mer.chargenScenarios.component.Loadouts")

---@class ChargenScenarios.ScenarioMenu
local ScenarioMenu = {}

local menuId = tes3ui.registerID("Mer_ScenarioSelectorMenu")
local descriptionHeaderID = tes3ui.registerID("Mer_ScenarioSelectorDescriptionHeader")
local descriptionID = tes3ui.registerID("Mer_ScenarioSelectorDescription")
local locationDropdownBlockID = tes3ui.registerID("Mer_ScenarioSelectorLocationDropdownBlock")
local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("ScenarioMenu")

--Register the Menu

Loadouts.register{
    id = "scenario",
    callback = function()
        local scenario = Scenario.getSelectedScenario()
        if not scenario then
            return Scenario.registeredScenarios.vanilla.itemList
        end
        --We do scenario items last, so noDuplicates etc can be applied
        scenario.itemList.priority = -100
        return scenario.itemList
    end
}

---@type ChargenScenarios.ChargenMenu.config
local menu = {
    id = "scenarioMenu",
    name = "Chargen Scenarios",
    priority = -1000,
    buttonLabel= "Scenarios",
    getButtonValue = function(self)
        local scenario = Scenario.getSelectedScenario()
        return scenario and scenario.name or "None"
    end,
    getTooltip = function(self)
        local scenario = Scenario.getSelectedScenario()
        if scenario then
            return {
                header = scenario.name,
                description = scenario.description
            }
        end
    end,
    createMenu = function(self)
        ScenarioMenu.createScenarioMenu{
            scenarioList = Scenario.registeredScenarios,
            onScenarioSelected = function(scenario)
                logger:debug("Clicked scenario: %s", scenario.name)
                Scenario.setSelectedScenario(scenario)
            end,
            onOkayButton = function()
                self:okCallback()
            end,
            currentScenario = Scenario.getSelectedScenario()
        }
    end,
    validate = function(self)
        local scenario = Scenario.getSelectedScenario()
        return scenario == nil or scenario:checkRequirements()
    end,
    onStart = function(self)
        local scenario = Scenario.getSelectedScenario()
        logger:debug("Starting scenario: %s", scenario.name)
        scenario:start()
    end,
}
ChargenMenu.register(menu)

local function createScenarioListBlock(parent)
    local scenarioListBlock = parent:createVerticalScrollPane{
        id = tes3ui.registerID("scenarioListBlock")
    }
    scenarioListBlock.heightProportional = 1.0
    scenarioListBlock.minWidth = 300
    scenarioListBlock.autoWidth = true
    scenarioListBlock.paddingAllSides = 4
    scenarioListBlock.borderRight = 6
    return scenarioListBlock
end


local function sortListAlphabetically(list)
    local alphabetSort = function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end
    local sortedList = {}
    for _, background in pairs(list) do
        table.insert(sortedList, background)
    end
    table.sort(sortedList, alphabetSort)
    return sortedList
end

local function sortLocationListAlphabetically(locationList)
    local alphabetSort = function(a, b)
        return string.lower(a:getName()) < string.lower(b:getName())
    end
    local sortedList = {}
    for _, location in pairs(locationList) do
        table.insert(sortedList, location)
    end
    table.sort(sortedList, alphabetSort)
    return sortedList
end

---@param scenario ChargenScenariosScenario
local function onClickScenario(scenario)
    logger:debug("Clicked Scenario %s", scenario.name)
    local menu = tes3ui.findMenu(menuId)
    if not menu then return end
    local header = menu:findChild(descriptionHeaderID)
    header.text = scenario.name

    local description = menu:findChild(descriptionID) --[[@as tes3uiElement]]
    description.text = table.concat({
        scenario.description,
        scenario.requirements:getDescription()
    }, "\n\n")

    local okayButton = menu:findChild(tes3ui.registerID("Mer_ScenarioSelectorMenu_okayButton")) --[[@as tes3uiElement]]

    local scenarioValid = scenario:checkRequirements()

    if not scenarioValid then
        header.color = tes3ui.getPalette("disabled_color")
        okayButton.widget.state = 2
        okayButton.disabled = true
    else
        header.color = tes3ui.getPalette("header_color")
        okayButton.widget.state = 1
        okayButton.disabled = false
    end

    local locationDropdownBlock = menu:findChild(locationDropdownBlockID) --[[@as tes3uiElement]]
    locationDropdownBlock:destroyChildren()

    local validLocations = scenario:getValidLocations()
    if scenarioValid and #validLocations > 1 then

        local button = locationDropdownBlock:createButton{ text = "Location: " .. scenario:getStartingLocation():getName()}
        button:register("mouseClick", function()
            local selectLocationMenu = tes3ui.createMenu{ id = tes3ui.registerID("Mer_SelectLocationMenu"), fixedFrame = true }
            tes3ui.enterMenuMode(selectLocationMenu.id)
            local outerBlock = selectLocationMenu:createBlock()
            outerBlock.flowDirection = "top_to_bottom"
            outerBlock.autoHeight = true
            outerBlock.autoWidth = true

            local heading = outerBlock:createLabel{ text = "Select Location:"}
            heading.color = tes3ui.getPalette("header_color")

            local currentLocationText = outerBlock:createLabel{ text = scenario:getStartingLocation():getName()}

            local locationListBlock =outerBlock:createVerticalScrollPane{}

            local rowHeight = 23
            local maxEntries = 10

            locationListBlock.minHeight = math.clamp(#validLocations * rowHeight, rowHeight*2, rowHeight*maxEntries) + 4
            locationListBlock.maxHeight = locationListBlock.minHeight
            locationListBlock.autoHeight = false
            locationListBlock.minWidth = 300
            locationListBlock.autoWidth = true
            locationListBlock.paddingAllSides = 4
            locationListBlock.borderRight = 6

            validLocations = sortLocationListAlphabetically(validLocations)

            for _, location in ipairs(validLocations) do
                local locationButton = locationListBlock:createTextSelect{
                    text = location:getName(),
                    id = tes3ui.registerID("locationButton_" .. location:getName())
                }
                locationButton.autoHeight = true
                locationButton.widthProportional = 1.0
                locationButton.paddingAllSides = 2
                locationButton.borderAllSides = 2
                locationButton:register("mouseClick", function()
                    scenario.decidedLocation = location
                    currentLocationText.text = location:getName()
                    button.text = "Location: " .. location:getName()
                end)
            end

            local buttonsBlock = outerBlock:createBlock()
            buttonsBlock.flowDirection = "left_to_right"
            buttonsBlock.widthProportional = 1.0
            buttonsBlock.autoHeight = true

            --randomise button
            local randomButton = buttonsBlock:createButton{ text = "Random"}
            randomButton:register("mouseClick", function()
                local index = math.random(#validLocations)
                local list = locationListBlock:getContentElement().children
                list[index]:triggerEvent("mouseClick")
            end)

            --okay button
            local okayButton = buttonsBlock:createButton{ text = "Ok"}
            okayButton:register("mouseClick", function()
                selectLocationMenu:destroy()
            end)

            selectLocationMenu:updateLayout()
        end)
    end

    description:updateLayout()
end

---@param listBlock tes3uiElement
---@param list ChargenScenariosScenario[]
---@param onScenarioSelected fun(scenario: ChargenScenariosScenario)
---@param currentScenario ChargenScenariosScenario
local function populateScenarioList(listBlock, list, onScenarioSelected, currentScenario)
    local validScenarios = 0
    for _, scenario in ipairs(list) do
        if scenario:isVisible() then
            local scenarioButton = listBlock:createTextSelect{
                text = scenario.name,
                id = tes3ui.registerID("scenarioButton_" .. scenario.name)
            }
            scenarioButton.autoHeight = true
            scenarioButton.widthProportional = 1.0
            scenarioButton.paddingAllSides = 2
            scenarioButton.borderAllSides = 2
            if not scenario:checkRequirements() then
                scenarioButton.color = tes3ui.getPalette("disabled_color")
                scenarioButton.widget.idle = tes3ui.getPalette("disabled_color")
            end
            scenarioButton:register("mouseClick", function()
                onClickScenario(scenario)
                onScenarioSelected(scenario)
            end)
            if scenario == currentScenario then
                timer.frame.delayOneFrame(function()
                    logger:debug("Crurent Scenario exists, triggering mouse click")
                    scenarioButton:triggerEvent("mouseClick")
                end)
            end
            validScenarios = validScenarios + 1
        else
            logger:debug("Scenario %s is hidden or has no valid locations", scenario.name)
        end
    end
    logger:debug("Found %s valid scenarios", validScenarios)
end

---@param parent tes3uiElement
local function createDescriptionBlock(parent)
    local descriptionBlock = parent:createThinBorder()
    descriptionBlock.heightProportional = 1.0
    descriptionBlock.width = 400
    descriptionBlock.borderRight = 10
    descriptionBlock.flowDirection = "top_to_bottom"
    descriptionBlock.paddingAllSides = 10

    local descriptionHeader = descriptionBlock:createLabel{ id = descriptionHeaderID, text = ""}
    descriptionHeader.color = tes3ui.getPalette("header_color")

    local descriptionText = descriptionBlock:createLabel{id = descriptionID, text = ""}
    descriptionText.wrapText = true
    descriptionText.heightProportional = 1.0


    local locationDropdownBlock = descriptionBlock:createBlock{ id = locationDropdownBlockID}
    locationDropdownBlock.autoHeight = true
    locationDropdownBlock.widthProportional = 1.0
    locationDropdownBlock.childAlignX = 0.5

    return descriptionText
end


---@param e { scenarioList: ChargenScenariosScenario[], onScenarioSelected: fun(scenario: ChargenScenariosScenario), onOkayButton: fun(), currentScenario: ChargenScenariosScenario}
function ScenarioMenu.createScenarioMenu(e)
    logger:debug("Creating Scenario Selector Menu")
    local scenarioList = sortListAlphabetically(table.values(e.scenarioList))
    local onScenarioSelected = e.onScenarioSelected
    local onOkayButton = e.onOkayButton
    local currentScenario = e.currentScenario

    logger:debug("- Creating menu")
    local menu = tes3ui.createMenu{ id = menuId, fixedFrame = true }
    local outerBlock = Menu.createOuterBlock{
        id = "Mer_ScenarioSelectorMenu_outerBlock",
        parent = menu
    }
    --outer block
    Menu.createHeading{
        id = "Mer_ScenarioSelectorMenu_heading",
        parent = outerBlock,
        text = "Select your Scenario:"
    }

    local innerBlock = Menu.createInnerBlock{
        id = "Mer_ScenarioSelectorMenu_innerBlock",
        parent = outerBlock,
        height = 400
    }
    --inner block
    local scenarioListBlock = createScenarioListBlock(innerBlock)

    logger:debug("- Populating Scenario List")
    populateScenarioList(scenarioListBlock, scenarioList, onScenarioSelected, currentScenario)
    createDescriptionBlock(innerBlock)
    --Buttons
    local buttonsBlock = Menu.createButtonsBlock{
        id = "Mer_ScenarioSelectorMenu_buttonsBlock",
        parent = outerBlock
    }

    --Randomize button
    Menu.createButton{
        id = "Mer_ScenarioSelectorMenu_randomButton",
        text = "Random",
        parent = buttonsBlock,
        callback = function()
            local list = scenarioListBlock:getContentElement().children
            list[ math.random(#list) ]:triggerEvent("mouseClick")
        end
    }

    --Ok button
    Menu.createButton{
        id = "Mer_ScenarioSelectorMenu_okayButton",
        text = "Ok",
        parent = buttonsBlock,
        callback = function()
            tes3ui.findMenu(menuId):destroy()
            onOkayButton()
        end
    }

    logger:debug("- Updating Layout")
    menu:updateLayout()
    logger:debug("- Entering Menu Mode")
    tes3ui.enterMenuMode(menuId)
    logger:debug("- Clicking the first scenario")
    scenarioListBlock:getContentElement().children[1]:triggerEvent("mouseClick")
end


return ScenarioMenu


