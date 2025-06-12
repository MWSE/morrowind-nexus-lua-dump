local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("LoadoutUI")
local ItemList = require("mer.chargenScenarios.component.ItemList")

---@class ChargenScenarios.Util.LoadoutUI
local LoadoutUI = {}

---@param e { itemList : ChargenScenarios.ItemList }
local function createLoadoutTooltip(e)
    local tooltip = tes3ui.createTooltipMenu()
    local outerBlock = tooltip:createBlock{}
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true
    outerBlock.paddingAllSides = 6

    local heading = outerBlock:createLabel{ text = e.itemList.name }
    heading.color = tes3ui.getPalette("header_color")
    heading.borderTop = 6
    heading.borderBottom = 6
    heading.borderLeft = 6
    heading.borderRight = 6
    heading.autoWidth = true
    heading.autoHeight = true

    if e.itemList.description then
        local description = outerBlock:createLabel{ text = e.itemList.description }
        description.wrapText = true
        description.borderTop = 6
        description.borderBottom = 6
        description.borderLeft = 6
        description.borderRight = 6
        description.autoWidth = true
        description.autoHeight = true
        description.maxWidth = 300
    end

    local descriptions = e.itemList:getDescriptionList()
    for _, description in ipairs(descriptions) do
        local label = outerBlock:createLabel{ text = description }
        label.borderTop = 6
        label.borderBottom = 6
        label.borderLeft = 6
        label.borderRight = 6
        label.autoWidth = true
        label.autoHeight = true
    end
end

local function getColor(active)
    return active and tes3ui.getPalette("normal_color") or tes3ui.getPalette("disabled_color")
end

local function getToggleText(active)
    return active and "Удалить" or "Добавить"
end

function LoadoutUI.clickRow(rowBlock, doOnClick)
    local itemList = rowBlock:getLuaData("loadout")
    if not itemList then
        logger:debug("No loadout found")
        return
    end
    local button = rowBlock:findChild(tes3ui.registerID("ChargenScenarios_LoadoutsMenu_button"))
    local label = rowBlock:findChild(tes3ui.registerID("ChargenScenarios_LoadoutsMenu_label"))
    local canClick = rowBlock:getLuaData("canClick")
    if canClick ~= nil and not canClick(itemList) then
        tes3.messageBox("Вы достигли максимального количества наборов предметов, которые вы можете добавить.")
        return
    end
    itemList.active = not itemList.active
    button.text = getToggleText(itemList.active)
    local color = getColor(itemList.active)
    label.color = color
    rowBlock:updateLayout()
    local onClick = rowBlock:getLuaData("onClick")
    if onClick and doOnClick then
        onClick()
    end
end

---@param e { parent: tes3uiElement, itemList : ChargenScenarios.ItemList, onClick: fun(), canClick: fun(ChargenScenarios.ItemList):boolean }
function LoadoutUI.createLoadoutRow(e)
    local outerBlock = e.parent:createThinBorder{}
    outerBlock.flowDirection = "left_to_right"
    outerBlock.widthProportional = 1.0
    outerBlock.autoHeight = true
    outerBlock.paddingAllSides = 6
    outerBlock:register("help", function()
        createLoadoutTooltip(e)
    end)
    outerBlock:setLuaData("loadout", e.itemList)
    outerBlock:setLuaData("onClick", e.onClick)
    outerBlock:setLuaData("canClick", e.canClick)

    local color = getColor(e.itemList.active)

    local label = outerBlock:createLabel{
        id = "ChargenScenarios_LoadoutsMenu_label",
        text = e.itemList.name
    }
    label.borderAllSides = 6
    label.autoWidth = true
    label.autoHeight = true
    label.color = color
    label:register("help", function()
        createLoadoutTooltip(e)
    end)
    local button
    if not e.itemList.defaultActive then
        local buttonText = getToggleText(e.itemList.active)
        button = outerBlock:createButton{
            id = "ChargenScenarios_LoadoutsMenu_button",
            text = buttonText
        }
        button.absolutePosAlignX = 1.0
        button.absolutePosAlignY = 0.5
        button:setLuaData("loadout", e.itemList)
        button:register("mouseClick", function()
            logger:debug("Clicked %s", e.itemList.name)
            LoadoutUI.clickRow(outerBlock, true)
        end)
    end


end



return LoadoutUI
