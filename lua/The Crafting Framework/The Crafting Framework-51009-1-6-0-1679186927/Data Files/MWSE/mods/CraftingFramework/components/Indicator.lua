local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Indicator")

---@class CraftingFramework.Indicator.new.params
---@field reference tes3reference?
---@field item tes3object|tes3item|tes3misc?
---@field itemData tes3itemData?

---@class CraftingFramework.Indicator.data
---@field objectId string The object id to register the indicator for
---@field name string The name to display in the tooltip.
---@field craftedOnly boolean If true, the indicator will only show if the object is crafted.
---@field additionalUI fun(self: CraftingFramework.Indicator, parent: tes3uiElement) A function that adds additional UI elements to the tooltip.

---@class CraftingFramework.Indicator : CraftingFramework.Indicator.data
---@field reference tes3reference
---@field item tes3object|tes3item|tes3misc
---@field dataHolder tes3itemData|tes3reference
Indicator = {}
---@type table<string, CraftingFramework.Indicator.data> List of registered indicator objects, indexed by object id
Indicator.registeredObjects = {}

---@param data CraftingFramework.Indicator.data
function Indicator.register(data)
    logger:assert(type(data.objectId) == "string" , "data.objectId is required")
    if Indicator.registeredObjects[data.objectId:lower()] then
        logger:warn("Indicator.register: %s is already registered", data.objectId)
        table.copy(data, Indicator.registeredObjects[data.objectId:lower()])
    else
        Indicator.registeredObjects[data.objectId:lower()] = data
    end

    logger:debug("Registered %s as Indicator", data.objectId)
end

---@param e CraftingFramework.Indicator.new.params
---@return CraftingFramework.Indicator|nil
function Indicator:new(e)
    local object = e.item or e.reference.baseObject
    if not object then return end
    local data = Indicator.registeredObjects[object.id:lower()]
    if not data then return end
    if not (data.name or data.additionalUI) then return end
    local indicator = table.copy(data)
    indicator.item = object
    indicator.dataHolder = e.itemData or e.reference
    setmetatable(indicator, self)
    self.__index = self
    return indicator
end

local id_indicator = tes3ui.registerID("CraftingFramework:activatorTooltip")
local id_contents = tes3ui.registerID("CraftingFramework:activatorTooltipContents")
local id_label = tes3ui.registerID("CraftingFramework:activatorTooltipLabel")
local icon_block = tes3ui.registerID("CraftingFramework:activatorTooltipIconBlock")
local function getTooltip()
    local MenuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if not MenuMulti then return end
    return MenuMulti:findChild(id_indicator)
end

function Indicator:createOrUpdateTooltipMenu()
    local indicator = Indicator.registeredObjects[self.item.id:lower()]
    local headerText = indicator.name
    local MenuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if not MenuMulti then return end
    local tooltipMenu = MenuMulti:findChild(id_indicator)
        or MenuMulti:createBlock{ id = id_indicator }
    tooltipMenu.visible = true
    tooltipMenu:destroyChildren()
    tooltipMenu.absolutePosAlignX = 0.5
    tooltipMenu.absolutePosAlignY = 0.03
    tooltipMenu.autoHeight = true
    tooltipMenu.autoWidth = true
    local labelBackground = tooltipMenu:createRect({color = {0, 0, 0}})
    labelBackground.autoHeight = true
    labelBackground.autoWidth = true
    local labelBorder = labelBackground:createThinBorder({id = id_contents })
    labelBorder.autoHeight = true
    labelBorder.autoWidth = true
    labelBorder.childAlignX = 0.5
    labelBorder.paddingAllSides = 10
    labelBorder.flowDirection = "top_to_bottom"

    if headerText then
        local headerBlock = labelBorder:createBlock()
        headerBlock.autoHeight = true
        headerBlock.autoWidth = true
        headerBlock.flowDirection = "left_to_right"
        headerBlock.childAlignY = 0.5
        local iconBlock = headerBlock:createBlock{ id = icon_block }
        iconBlock.autoHeight = true
        iconBlock.autoWidth = true
        local header = headerBlock:createLabel{ id = id_label, text = headerText or "" }
        header.autoHeight = true
        header.autoWidth = true
        header.color = tes3ui.getPalette("header_color")
    end
    if indicator.additionalUI then
        local additionalUIBlock = labelBorder:createBlock()
        additionalUIBlock.autoHeight = true
        additionalUIBlock.autoWidth = true
        indicator:additionalUI(additionalUIBlock)
    end

    return labelBorder
end

function Indicator:doBlockNonCrafted()
    local isCrafted = self.dataHolder
    and self.dataHolder.data
    and self.dataHolder.data.crafted == true
    return self.craftedOnly and not isCrafted
end

--- Update the indicator with the given reference
function Indicator:update()
    --get menu
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    --If its an activator with a name, it'll already have a tooltip
    local hasObjectName = self.item.name and self.item.name ~= ""
    local hasRegisteredName = self.name and self.name ~= ""

    local showIndicator = menu
        and self
        and ( hasRegisteredName or self.additionalUI )
        and (not hasObjectName)
        and (not self:doBlockNonCrafted())
    if showIndicator then
        self:createOrUpdateTooltipMenu()
    else
        Indicator.disable()
    end
end

---Hide the indicator if it's visible
function Indicator.disable()
    local tooltipMenu = getTooltip()
    if tooltipMenu then
        tooltipMenu.visible = false
    end
end

return Indicator