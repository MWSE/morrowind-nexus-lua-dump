local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("Feature:Companions")

---@class ChargenScenarios.CompanionsFeature.Companion
---@field id string The ID of the companion
---@field description? string A description of the companion
---@field callback? fun(companionRef:tes3reference) A function to call to perform any actions required to enable the companion

---@class ChargenScenarios.CompanionsFeature.AvailableCompanion : ChargenScenarios.CompanionsFeature.Companion
---@field object tes3npc|tes3creature The object of the companion

---@class ChargenScenarios.CompanionsFeature : ChargenScenarios.ExtraFeature
---@field selectedCompanions table<string, boolean> A list of currently selected companions
---@field registeredCompanions table<string, ChargenScenarios.CompanionsFeature.Companion> A list of companions that have been registered
local CompanionsFeature = {
    id = "companions",
    name = "Companions",
    registeredCompanions = {},
    selectedCompanions = {},
}

event.register("loaded", function()
    CompanionsFeature.selectedCompanions = {}
end)

function CompanionsFeature.addCompanion(companion)
    assert(companion.id, "No id provided")
    assert(CompanionsFeature.registeredCompanions[companion.id] == nil, "Companion already registered")
    CompanionsFeature.registeredCompanions[companion.id] = companion
end

---@return ChargenScenarios.CompanionsFeature.AvailableCompanion[] companions A list of available companions
function CompanionsFeature.getAvailableCompanions()
    local availableCompanions = {}
    for id, companion in pairs(CompanionsFeature.registeredCompanions) do
        local object = tes3.getObject(id)
        if object then
            local availableCompanion = table.copy(companion)
            availableCompanion.object = object
            table.insert(availableCompanions, availableCompanion)
        end
    end
    ---@param a ChargenScenarios.CompanionsFeature.AvailableCompanion
    ---@param b ChargenScenarios.CompanionsFeature.AvailableCompanion
    table.sort(availableCompanions, function(a, b)
        if CompanionsFeature.isSelected(a) and not CompanionsFeature.isSelected(b) then
            return true
        elseif not CompanionsFeature.isSelected(a) and CompanionsFeature.isSelected(b) then
            return false
        else
            return a.object.name < b.object.name
        end
    end)
    return availableCompanions
end

function CompanionsFeature.getSelectedCompanions()
    local selectedCompanions = {}
    for id, isSelected in pairs(CompanionsFeature.selectedCompanions) do
        if isSelected then
            selectedCompanions[id] = true
        end
    end
    return selectedCompanions
end


function CompanionsFeature.getTooltip()
    local companions = CompanionsFeature.getSelectedCompanions()
    local tooltip = "Companions: "
    for id in pairs(companions) do
        local companion = CompanionsFeature.registeredCompanions[id]
        if companion then
            local object = tes3.getObject(id)
            tooltip = tooltip .. "\n - " .. object.name
        end
    end
    return tooltip
end

---@return string
function CompanionsFeature.getDescription(companion)
    local companionObject = tes3.getObject(companion.id)
    if not companionObject then
        return "Does not exist"
    end
    local description = string.format("Name: %s \nLevel: %s",
        companionObject.name,
        companionObject.level
    )
    if companion.description then
        description = description .. "\n" .. companion.description
    end

    return description
end

function CompanionsFeature.isSelected(companion)
    return CompanionsFeature.selectedCompanions[companion.id] == true
end

---@param parent tes3uiElement
---@param companion ChargenScenarios.CompanionsFeature.AvailableCompanion
---@param detailsPane tes3uiElement
function CompanionsFeature.createCompanionButton(parent, companion, detailsPane)
    local onClick = function ()
        logger:debug("Clicked on companion: %s", companion.id)
        CompanionsFeature.updateDetailsPane(detailsPane, companion)
        tes3.playSound{ sound = "Menu Click" }
    end

    local block = parent:createThinBorder()
    block.autoHeight = true
    block.widthProportional = 1.0
    block.flowDirection = "left_to_right"
    block.paddingAllSides = 6
    block:register("mouseClick", onClick)

    local function setWidgetState(textSelectLabel)
        textSelectLabel.widget.state = CompanionsFeature.isSelected(companion) and tes3.uiState.active or tes3.uiState.normal
    end

    --Name
    local nameLabel = block:createTextSelect{ text = companion.object.name }
    nameLabel.widthProportional = 1.0
    setWidgetState(nameLabel)
    nameLabel:register("mouseClick", onClick)

end

---@param detailsPane tes3uiElement
---@param companion ChargenScenarios.CompanionsFeature.AvailableCompanion
function CompanionsFeature.updateDetailsPane(detailsPane, companion)
    logger:debug("Updating details pane for companion: %s", companion.id)
    detailsPane:destroyChildren()

    detailsPane.flowDirection = "top_to_bottom"
    detailsPane.paddingAllSides = 10
    detailsPane.autoHeight = true
    detailsPane.widthProportional = 1.0

    local contentBlock = detailsPane:createBlock{ id = "ChargenScenarios:CompanionDetailsContentBlock" }
    contentBlock.flowDirection = "top_to_bottom"
    contentBlock.widthProportional = 1.0
    contentBlock.heightProportional = 1.0

    -- Name header
    local nameLabel = contentBlock:createLabel{ text = companion.object.name }
    nameLabel.color = tes3ui.getPalette(tes3.palette.headerColor)
    nameLabel.borderBottom = 5

    -- Level
    local levelLabel = contentBlock:createLabel{ text = string.format("Level: %s", companion.object.level) }
    levelLabel.borderBottom = 3

    local isNPC = companion.object.objectType == tes3.objectType.npc

    -- Race and Sex for NPCs
    if isNPC then
        local raceLabel = contentBlock:createLabel{ text = string.format("Race: %s", companion.object.race.name) }
        local sexLabel = contentBlock:createLabel{ text = string.format("Sex: %s", companion.object.female and "Female" or "Male") }
        local classLabel = contentBlock:createLabel{ text = string.format("Class: %s", companion.object.class.name) }
        classLabel.borderBottom = 3
    else
        -- For creatures, show type
        local typeLabel = contentBlock:createLabel{ text = "Type: Creature" }
        typeLabel.borderBottom = 3
    end

    -- Custom description
    if companion.description then
        local descriptionHeader = contentBlock:createLabel{ text = "Description:" }
        descriptionHeader.color = tes3ui.getPalette(tes3.palette.headerColor)
        descriptionHeader.borderTop = 5
        descriptionHeader.borderBottom = 3

        local descriptionLabel = contentBlock:createLabel{ text = companion.description }
        descriptionLabel.wrapText = true
        descriptionLabel.borderBottom = 5
    end


    -- Select button
    local buttonBlock = detailsPane:createBlock()
    buttonBlock.widthProportional = 1.0
    buttonBlock.autoHeight = true
    buttonBlock.autoWidth = true
    buttonBlock.borderTop = 10
    buttonBlock.childAlignX = 0.5

    local isSelected = CompanionsFeature.isSelected(companion)
    local selectButton = buttonBlock:createButton{ text = isSelected and "Selected" or "Select" }
    selectButton:register("mouseClick", function()
        CompanionsFeature.selectedCompanions[companion.id] = not CompanionsFeature.selectedCompanions[companion.id]
        -- Find the companion list parent to refresh it
        local companionsList = detailsPane:getTopLevelMenu():findChild("ChargenScenarios:CompanionsList")
        if companionsList then
            CompanionsFeature.populateCompanionList(companionsList, detailsPane)
        end
        CompanionsFeature.updateDetailsPane(detailsPane, companion)
        tes3.playSound{ sound = "Menu Click" }
    end)

    detailsPane:getTopLevelMenu():updateLayout()
end

---@param parent tes3uiElement
---@param detailsPane tes3uiElement
function CompanionsFeature.populateCompanionList(parent, detailsPane)
    parent:getContentElement():destroyChildren()
    local companions = CompanionsFeature.getAvailableCompanions()
    for _, companion in pairs(companions) do
        CompanionsFeature.createCompanionButton(parent, companion, detailsPane)
    end
    parent.widget:contentsChanged()

    -- Update details pane with first companion if available
    if #companions > 0 then
        CompanionsFeature.updateDetailsPane(detailsPane, companions[1])
    end
end

---@param e ChargenScenarios.ExtraFeature.callbackParams
CompanionsFeature.callback = function(e)
    local menu = tes3ui.createMenu{ id = "ChargenScenarios:CompanionsMenu", fixedFrame = true }
    menu.minWidth = 700
    menu.minHeight = 500
    menu.autoHeight = true

    local mainBlock = menu:createBlock()
    mainBlock.flowDirection = "top_to_bottom"
    mainBlock.autoHeight = true
    mainBlock.widthProportional = 1.0
    mainBlock.childAlignX = 0.5

    local header = mainBlock:createLabel{ text = "Select Companions:" }
    header.color = tes3ui.getPalette(tes3.palette.headerColor)
    header.borderBottom = 5

    -- Container for the two-panel layout
    local contentBlock = mainBlock:createBlock()
    contentBlock.flowDirection = "left_to_right"
    contentBlock.autoHeight = true
    contentBlock.autoWidth = true
    contentBlock.widthProportional = 1.0

    -- Left panel: Companion list
    local leftPanel = contentBlock:createBlock()
    leftPanel.flowDirection = "top_to_bottom"
    leftPanel.autoHeight = true
    leftPanel.widthProportional = 1.0

    local listLabel = leftPanel:createLabel{ text = "Companions:" }
    listLabel.borderBottom = 3

    local companionsList = leftPanel:createVerticalScrollPane{ id = "ChargenScenarios:CompanionsList" }
    companionsList.minHeight = 400
    companionsList.widthProportional = 1.0

    -- Right panel: Details
    local rightPanel = contentBlock:createBlock()
    rightPanel.flowDirection = "top_to_bottom"
    rightPanel.autoHeight = true
    rightPanel.widthProportional = 1.0
    rightPanel.borderLeft = 10

    local detailsLabel = rightPanel:createLabel{ text = "Details:" }
    detailsLabel.borderBottom = 3

    local detailsPane = rightPanel:createThinBorder()
    detailsPane.minHeight = 400
    detailsPane.autoHeight = true
    detailsPane.widthProportional = 1.0

    CompanionsFeature.updateDetailsPane(detailsPane, CompanionsFeature.getAvailableCompanions()[1])
    CompanionsFeature.populateCompanionList(companionsList, detailsPane)

    --buttons
    local buttonBlock = mainBlock:createBlock()
    buttonBlock.widthProportional = 1.0
    buttonBlock.autoHeight = true
    buttonBlock.borderTop = 10

    --Random - pick one random companion
    local randomButton = buttonBlock:createButton{ text = "Random" }
    randomButton:register("mouseClick", function()
        CompanionsFeature.selectedCompanions = {}
        local availableCompanions = CompanionsFeature.getAvailableCompanions()
        local selectedCompanion = table.choice(availableCompanions)
        if selectedCompanion then
            CompanionsFeature.selectedCompanions[selectedCompanion.id] = true
            CompanionsFeature.populateCompanionList(companionsList, detailsPane)
        end
    end)

    --Reset
    local resetButton = buttonBlock:createButton{ text = "Reset" }
    resetButton:register("mouseClick", function()
        CompanionsFeature.selectedCompanions = {}
        CompanionsFeature.populateCompanionList(companionsList, detailsPane)
    end)

    --Confirm
    local confirmButton = buttonBlock:createButton{ text = "Confirm" }
    confirmButton:register("mouseClick", function()
        menu:destroy()
        e.goBack()
    end)

    menu:updateLayout()
end

function CompanionsFeature.isActive()
    return table.size(CompanionsFeature.getSelectedCompanions()) > 0
end

function CompanionsFeature.showFeature()
    return table.size(CompanionsFeature.getAvailableCompanions()) > 0
end

function CompanionsFeature.onStart()
    logger:debug("Starting companions")
    local selectedCompanions = CompanionsFeature.getSelectedCompanions()
    for id in pairs(selectedCompanions) do
        local companion = CompanionsFeature.registeredCompanions[id]
        if companion then
            --First find if the companion already exists, and disable it
            local existingCompanion = tes3.getReference(id)
            if existingCompanion then
                logger:debug("Disabling existing companion: %s", id)
                existingCompanion:disable()
            end

            logger:debug("Adding companion: %s", id)
            local companionRef = common.placeBehindPlayer{
                object = companion.id,
                distanceBehind = 50
            }
            if companion.callback then companion.callback(companionRef) end
            tes3.setAIFollow{
                reference = companionRef,
                target = tes3.player
            }
        end
    end
end

return CompanionsFeature