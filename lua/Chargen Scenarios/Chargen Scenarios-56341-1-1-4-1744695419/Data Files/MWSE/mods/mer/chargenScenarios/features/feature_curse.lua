local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("Feature:Curses")
local ExtraFeatures = require("mer.chargenScenarios.component.ExtraFeatures")

---@class ChargenScenarios.CurseFeature.Curse
---@field name string
---@field spellId string?
---@field startScript string?
---@field stopScript string?

---@type ChargenScenarios.CurseFeature.Curse[]
local curses = {
    { name = "Lycanthropy", spellId = "werewolf blood" },
    { name = "Vampire (Aundae Clan)", spellId = "vampire blood aundae", startScript = "vampire_aundae_pc" },
    { name = "Vampire (Berne Clan)", spellId = "vampire blood berne", startScript = "vampire_berne_pc" },
    { name = "Vampire (Quarra Clan)", spellId = "vampire blood quarra", startScript = "vampire_quarra_pc" },
}

---@class ChargenScenarios.CurseFeature
local CurseFeature = {
    ---@type ChargenScenarios.CurseFeature.Curse?
    currentCurse = nil,
}

function CurseFeature.reset()
    CurseFeature.currentCurse = nil
end

---@param curse ChargenScenarios.CurseFeature.Curse
function CurseFeature.setCurse(curse)
    CurseFeature.currentCurse = curse
end

---@param curse ChargenScenarios.CurseFeature.Curse
---@return boolean
function CurseFeature.isSelected(curse)
    return CurseFeature.currentCurse == curse
end

---@param e { curse: ChargenScenarios.CurseFeature.Curse, parent: tes3uiElement }
function CurseFeature.createCurseButton(e)
    local textSelect = e.parent:createTextSelect{ text = e.curse.name }
    textSelect:register("mouseClick", function()
        local wasSelected = CurseFeature.isSelected(e.curse)
        logger:debug("Clicked on curse: %s", e.curse.name)
        CurseFeature.setCurse(wasSelected and nil or e.curse)
        CurseFeature.populateCurses(e.parent)
    end)
    textSelect.widget.state = CurseFeature.isSelected(e.curse) and tes3.uiState.active or tes3.uiState.normal
end

---@param parent tes3uiElement
function CurseFeature.populateCurses(parent)
    logger:debug("Populating curses")
    parent:destroyChildren()

    for _, curse in ipairs(curses) do
        CurseFeature.createCurseButton{
            curse = curse,
            parent = parent,
        }
    end

    parent:getTopLevelMenu():updateLayout()
end

---@param e ChargenScenarios.ExtraFeature.callbackParams
function CurseFeature.callback(e)
    local menu = tes3ui.createMenu{ id = "ChargenScenarios:CurseMenu", fixedFrame = true }
    menu.autoWidth = true
    menu:updateLayout()

    local block = menu:createBlock()
    block.autoWidth = true
    block.autoHeight = true
    block.flowDirection = "top_to_bottom"
    block.childAlignX = 0.5

    local header = block:createLabel{ text = "Select a Curse:" }
    header.color = tes3ui.getPalette("header_color")

    local cursesBlock = block:createThinBorder()
    cursesBlock.autoWidth = true
    cursesBlock.autoHeight = true
    cursesBlock.paddingAllSides = 10
    cursesBlock.borderAllSides = 10
    cursesBlock.flowDirection = "top_to_bottom"
    cursesBlock.childAlignX = 0.5

    CurseFeature.populateCurses(cursesBlock)

    local buttonsBlock = block:createBlock()
    buttonsBlock.autoWidth = true
    buttonsBlock.autoHeight = true

    local randomButton = buttonsBlock:createButton{ text = "Random" }
    randomButton:register("mouseClick", function()
        local options = table.copy(curses)
        local current = CurseFeature.currentCurse
        if current then
            for i, v in ipairs(options) do
                if v == current then
                    table.remove(options, i)
                    break
                end
            end
        end
        local randomCurse = options[math.random(#options)]
        logger:debug("Randomly selected curse: %s", randomCurse.name)
        CurseFeature.setCurse(randomCurse)
        CurseFeature.populateCurses(cursesBlock)
        menu:updateLayout()
    end)

    local resetButton = buttonsBlock:createButton{ text = "Reset" }
    resetButton:register("mouseClick", function()
        CurseFeature.reset()
        CurseFeature.populateCurses(cursesBlock)
        menu:updateLayout()
    end)

    local confirmButton = buttonsBlock:createButton{ text = "Confirm" }
    confirmButton:register("mouseClick", function()
        logger:debug("Selected curse: %s", CurseFeature.currentCurse and CurseFeature.currentCurse.name or "None")
        menu:destroy()
        e.goBack()
    end)

    menu:updateLayout()
end

function CurseFeature.onStart()
    local curse = CurseFeature.currentCurse
    if not curse then
        logger:debug("No curse selected")
        return
    end

    logger:debug("Applying curse: %s", curse.name)

    if curse.spellId then
        tes3.addSpell{
            reference = tes3.player,
            spell = curse.spellId,
        }
    end
    if curse.startScript then
        ---@diagnostic disable-next-line: deprecated
        mwscript.startScript{
            script = curse.startScript,
        }
    end
end

function CurseFeature.getTooltip()
    return CurseFeature.currentCurse and ("Curse: " .. CurseFeature.currentCurse.name) or "No curse selected."
end

function CurseFeature.isActive()
    return CurseFeature.currentCurse ~= nil
end

---@type ChargenScenarios.ExtraFeature
local feature = {
    id = "curses",
    name = "Vampirism/Lycanthropy",
    callback = CurseFeature.callback,
    onStart = CurseFeature.onStart,
    getTooltip = CurseFeature.getTooltip,
    isActive = CurseFeature.isActive,
}
ExtraFeatures.registerFeature(feature)

event.register("loaded", function()
    CurseFeature.reset()
end)
