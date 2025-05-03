local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("Feature:Spells")
local ExtraFeatures = require("mer.chargenScenarios.component.ExtraFeatures")

---@class ChargenScenarios.SpellsFeature :  ChargenScenarios.ExtraFeature
---@field selectedSpells table<string, boolean> A list of currently selected spells
local SpellsFeature = {
    id = "startingSpells",
    name = "Additional Spells",
    availableSpells = {
        --offensive
        "fire bite",
        "frostbite",
        "viperbite",
        "shock",
        --defensive
        "heal companion",
        "balyna's soothing balm",
        --tactical
        "buoyancy",
        "crying eye",
        "frenzying touch",
        "water breathing",
        "noise",
    }
}

---Get list of available spells, which includes those on player.object.spells
---@return table<string, true> A list of available spells
function SpellsFeature.getAvailableSpells()
    local availableSpells = {}
    for _, spellId in ipairs(SpellsFeature.availableSpells) do
        local spellObject = tes3.getObject(spellId)
        if spellObject then
            availableSpells[spellId] = true
        end
    end
    return availableSpells
end

SpellsFeature.resetSelectedSpells = function()
    tes3.player.tempData.ChargenScenarios_selectedSpells = nil
end


---@param spellId string The ID of the spell to set
---@param isSelected boolean Whether to select or deselect the spell
SpellsFeature.setSelectedSpell = function(spellId, isSelected)
    local selectedSpells = SpellsFeature.getSelectedSpells()
    if isSelected then
        selectedSpells[spellId] = true
    else
        selectedSpells[spellId] = false
    end
    tes3.player.tempData.ChargenScenarios_selectedSpells = selectedSpells
end

---@return table<string, boolean>
SpellsFeature.getSelectedSpells = function()
    local selectedSpells = tes3.player.tempData.ChargenScenarios_selectedSpells or {}
    return selectedSpells
end


---@return tes3spell[]
SpellsFeature.getSelectedSpellObjects = function()
    local selectedSpells = SpellsFeature.getSelectedSpells()
    local spellObjects = {}
    for spellId, active in pairs(selectedSpells) do
        if active then
            local spellObject = tes3.getObject(spellId)
            if spellObject then
                table.insert(spellObjects, spellObject)
            end
        end
    end
    return spellObjects
end


---@param e { spellId: string, parent: tes3uiElement }
function SpellsFeature.createSpellButton(e)
    local spellObject = tes3.getObject(e.spellId)
    if spellObject then
        local isSelected = SpellsFeature.getSelectedSpells()[e.spellId] or false
        logger:debug("Creating button for spell: %s. Selected: %s", spellObject.name, isSelected)
        local textSelect = e.parent:createTextSelect{ text = spellObject.name }
        textSelect:register("help", function()
            tes3ui.createTooltipMenu{ spell = spellObject }
        end)
        textSelect:register("mouseClick", function()
            logger:debug("Clicked on spell: %s", spellObject.name)
            isSelected = not isSelected
            SpellsFeature.setSelectedSpell(e.spellId, isSelected)
            SpellsFeature.populateSpells(e.parent)
        end)
        textSelect.widget.state = isSelected and tes3.uiState.active or tes3.uiState.normal
    end
end

---@param parent tes3uiElement The parent element to populate with spell buttons
function SpellsFeature.populateSpells(parent)
    logger:debug("Populating spells")
    parent:getContentElement():destroyChildren()

    local selectedSpells = SpellsFeature.getSelectedSpells()
    ---@type string[]
    local availableSpells = {}
    for spellId, _ in pairs(SpellsFeature.getAvailableSpells()) do
        table.insert(availableSpells, spellId)
    end
    --sort selected first, then alphabetically
    table.sort(availableSpells, function(a, b)
        if selectedSpells[a] and not selectedSpells[b] then
            return true
        elseif not selectedSpells[a] and selectedSpells[b] then
            return false
        else
            return a < b
        end
    end)

    -- Add spell selection logic here
    for _, spellId in ipairs(availableSpells) do
        logger:debug("Adding spell button for %s", spellId)
        SpellsFeature.createSpellButton{
            spellId = spellId,
            parent = parent,
        }
    end
    parent:getTopLevelMenu():updateLayout()
end

---@param e ChargenScenarios.ExtraFeature.callbackParams
function SpellsFeature.callback(e)

    local menu = tes3ui.createMenu{ id = "ChargenScenarios:SpellsMenu", fixedFrame = true }
    menu.autoWidth = true
    menu:updateLayout()

    local block = menu:createBlock()
    block.autoWidth = true
    block.autoHeight = true
    block.flowDirection = "top_to_bottom"
    block.childAlignX = 0.5

    local header = block:createLabel{ text = "Select Additional Spells:" }
    header.color = tes3ui.getPalette("header_color")

    local spellsBlock = block:createVerticalScrollPane()
    spellsBlock.autoWidth = true
    spellsBlock.autoHeight = true
    spellsBlock.minHeight = 300
    spellsBlock.minWidth = 300

    SpellsFeature.populateSpells(spellsBlock)

    ---horizontal buttons block
    local buttonsBlock = block:createBlock()
    buttonsBlock.autoWidth = true
    buttonsBlock.autoHeight = true

    ---Random button
    ---  Pick a number between 1 and the number of available spells
    ---  Select that many spells randomly from the available spells
    local randomButton = buttonsBlock:createButton{ text = "Random" }
    randomButton:register("mouseClick", function()
        local availableSpells = SpellsFeature.getAvailableSpells()
        local selectedSpells = {}
        for spellId, _ in pairs(availableSpells) do
            table.insert(selectedSpells, spellId)
        end
        local numToSelect = math.random(1, #selectedSpells)
        SpellsFeature.resetSelectedSpells()
        for i = 1, numToSelect do
            local randomIndex = math.random(#selectedSpells)
            local randomSpellId = selectedSpells[randomIndex]
            SpellsFeature.setSelectedSpell(randomSpellId, true)
            table.remove(selectedSpells, randomIndex)
        end
        SpellsFeature.populateSpells(spellsBlock)
        menu:updateLayout()
    end)

    --Add reset button
    local resetButton = buttonsBlock:createButton{ text = "Reset" }
    resetButton:register("mouseClick", function()
        SpellsFeature.resetSelectedSpells()
        SpellsFeature.populateSpells(spellsBlock)
        menu:updateLayout()
    end)

    -- Add a button to finalize the selection
    local finalizeButton = buttonsBlock:createButton{ text = "Confirm" }
    finalizeButton:register("mouseClick", function()
        logger:debug("Selected spells:")
        for spellId, _ in pairs(SpellsFeature.getSelectedSpells()) do
            logger:debug("- %s", spellId)
        end
        menu:destroy()
        e.goBack()
    end)

    menu:updateLayout()
end


function SpellsFeature.getTooltip(e)
    local spellObjects = SpellsFeature.getSelectedSpellObjects()
    if #spellObjects == 0 then
        return "No starting spells selected."
    end

    local tooltipMessage = "Starting Spells:\n"
    for _, spell in ipairs(spellObjects) do
        tooltipMessage = tooltipMessage .. "   - " .. spell.name .. "\n"
    end
    --remove last newline
    tooltipMessage = string.sub(tooltipMessage, 1, -2)

    return tooltipMessage
end

function SpellsFeature.isActive()
    return #SpellsFeature.getSelectedSpellObjects() > 0
end

function SpellsFeature.onStart()
    local selectedSpells = SpellsFeature.getSelectedSpellObjects()
    if #selectedSpells == 0 then
        logger:debug("No spells selected")
        return
    end

    logger:debug("Applying starting spells")

    timer.delayOneFrame(function()
        --Add missing spells
        for _, spell in ipairs(selectedSpells) do
            logger:debug("- Adding spell: %s", spell.id)
                tes3.addSpell{
                    reference = tes3.player,
                    spell = spell.id,
                    updateGUI = false
                }
        end
        tes3.updateMagicGUI{ reference = tes3.player }
    end)
end


ExtraFeatures.registerFeature(SpellsFeature)