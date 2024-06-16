local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("ValueModifier")

---@alias JOP.ValueModifier.calcValue fun(e: JOP.ValueModifier.calcValue.params): number

---@class JOP.ValueModifier.calcValue.params
---@field price number
---@field item tes3item
---@field itemData tes3itemData

---@class JOP.ValueModifier.register.data
---@field objectId string
---@field calcValue JOP.ValueModifier.calcValue

---@class JOP.ValueModifier
--- Modifies the value of an item based on its itemData
local ValueModifier = {
    ---@type table<string, JOP.ValueModifier.calcValue>
    registeredModifiers = {}
}

---@param data JOP.ValueModifier.register.data
function ValueModifier.register(data)
    local valueModifier = table.copy(data)
    logger:assert(valueModifier.objectId, "No objectId provided")
    logger:assert(valueModifier.calcValue, "No calcValue function provided")
    ValueModifier.registeredModifiers[valueModifier.objectId:lower()] = valueModifier.calcValue
end

---@param e calcBarterPriceEventData
local function calcValue(e)
    local valueModifier = ValueModifier.registeredModifiers[e.item.id:lower()]
    if valueModifier then
        logger:debug("Original Price: %s", e.price)
        e.price = valueModifier{
            price = e.price,
            item = e.item,
            itemData = e.itemData,
        }
        logger:debug("Modified Price: %s", e.price)
    end
end
event.register(tes3.event.calcBarterPrice, calcValue, {priority = -50})

---@param e uiObjectTooltipEventData
local function updateTooltipValue(e)
    local valueModifier = ValueModifier.registeredModifiers[e.object.id:lower()]
    if valueModifier then
        local tooltip = e.tooltip
        local price = tooltip:findChild(tes3ui.registerID("HelpMenu_value"))
        if price then
            local calcEventData = {
                item = e.object,
                itemData = e.itemData,
                --Remove "Value: "
                price = price.text:gsub("Value: ", ""),
            }
            local newPrice = valueModifier(calcEventData)
            price.text = "Value: " .. tostring(newPrice)
        end
        local uiExpPriceBlock = tooltip:findChild(tes3ui.registerID("UIEXP_Tooltip_IconGoldBlock"))
        if uiExpPriceBlock then
            local price = uiExpPriceBlock.children[2]
            if price then
                local calcEventData = {
                    item = e.object,
                    itemData = e.itemData,
                    price = price.text,
                }
                price.text = tostring(valueModifier(calcEventData))
            end
        end
    end
end

event.register(tes3.event.uiObjectTooltip, updateTooltipValue)

return ValueModifier