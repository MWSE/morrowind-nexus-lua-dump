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
function CompanionsFeature.createCompanionButton(parent, companion)
    local onClick = function ()
        logger:debug("Clicked on companion: %s", companion.id)
        CompanionsFeature.selectedCompanions[companion.id] = not CompanionsFeature.selectedCompanions[companion.id]
        CompanionsFeature.populateCompanionList(parent)
    end

    local block = parent:createThinBorder()
    block.autoHeight = true
    block.widthProportional = 1.0
    block.flowDirection = "top_to_bottom"
    block.paddingAllSides = 10

    --Name
    local isSelected = CompanionsFeature.isSelected(companion)
    local nameLabel = block:createTextSelect{ text = companion.object.name }
    nameLabel.widget.state = isSelected and tes3.uiState.active or tes3.uiState.normal
    nameLabel:register("mouseClick", onClick)

    --Level
    block:createLabel{ text = string.format("Level %s", companion.object.level) }

    --Race, Sex, and class if objectType == NPC
    if companion.object.objectType == tes3.objectType.npc then
        local raceSexLabel = string.format("%s, %s\nClass: %s",
            companion.object.race.name,
            companion.object.female and "Female" or "Male",
            companion.object.class.name)
        block:createLabel{ text = raceSexLabel }
    end

    if companion.description then
        local descriptionLabel = block:createLabel{ text = companion.description }
        descriptionLabel.widthProportional = 1.0
        descriptionLabel.wrapText = true
    end
end

---@param parent tes3uiElement
function CompanionsFeature.populateCompanionList(parent)
    parent:getContentElement():destroyChildren()
    local companions = CompanionsFeature.getAvailableCompanions()
    for _, companion in pairs(companions) do
        CompanionsFeature.createCompanionButton(parent, companion)
    end
    parent.widget:contentsChanged()
end

---@param e ChargenScenarios.ExtraFeature.callbackParams
CompanionsFeature.callback = function(e)
    local menu = tes3ui.createMenu{ id = "ChargenScenarios:CompanionsMenu", fixedFrame = true }
    menu.autoWidth = true
    menu:updateLayout()

    local block = menu:createBlock()
    block.autoHeight = true
    block.autoWidth = true
    block.flowDirection = "top_to_bottom"
    block.childAlignX = 0.5

    local header = block:createLabel{ text = "Select Companions:" }
    header.color = tes3ui.getPalette(tes3.palette.headerColor)
    header.borderBottom = 5

    local companionsList = block:createVerticalScrollPane()
    companionsList.autoHeight = true
    companionsList.autoWidth = true
    companionsList.minHeight = 400
    companionsList.minWidth = 250
    companionsList.widthProportional = 1.0

    CompanionsFeature.populateCompanionList(companionsList)

    --buttons
    local buttonBlock = block:createBlock()
    buttonBlock.autoWidth = true
    buttonBlock.autoHeight = true


    --Random - pick one random companion
    local randomButton = buttonBlock:createButton{ text = "Random" }
    randomButton:register("mouseClick", function()
        CompanionsFeature.selectedCompanions = {}
        local availableCompanions = CompanionsFeature.getAvailableCompanions()
        local selectedCompanion = table.choice(availableCompanions)
        if selectedCompanion then
            CompanionsFeature.selectedCompanions[selectedCompanion.id] = true
            CompanionsFeature.populateCompanionList(companionsList)
        end
    end)

    --Reset
    local resetButton = buttonBlock:createButton{ text = "Reset" }
    resetButton:register("mouseClick", function()
        CompanionsFeature.selectedCompanions = {}
        CompanionsFeature.populateCompanionList(companionsList)
    end)

    --Confirm
    local confirmButton = buttonBlock:createButton{ text = "Confirm" }
    confirmButton:register("mouseClick", function()
        menu:destroy()
        e.goBack()
    end)

    menu:updateLayout()
    companionsList.widget:contentsChanged()
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