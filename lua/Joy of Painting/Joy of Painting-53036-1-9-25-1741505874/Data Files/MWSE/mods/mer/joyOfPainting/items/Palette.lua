---@class JOP.Palette.params : JOP.ItemInstanceParams
---@field paletteItem JOP.PaletteItem?

---@class JOP.PaletteItem
---@field id string The id of the palette item. Must be a valid tes3item
---@field paintType string The paintType that this palette can be used with
---@field meshOverride string? The mesh to use for this palette item
---@field breaks boolean? **Default: false** Whether the palette breaks when uses run out
---@field fullByDefault boolean? **Default: false** Whether the palette is full by default
---@field uses number The number of uses for the palette
---@field paintValue number? The additional value when the palette is full of paint

---@class JOP.PaintType
---@field id string The id of the palette type
---@field name string The name of the palette type
---@field brushType? string The brush type to use for this palette. If not specified, this palette does not need a brush to use.
---@field refillMenu? CraftingFramework.MenuActivator
---@field action "Draw" | "Sketch" | "Paint" | string The action to take when using this paint type

local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Palette")
local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local CraftingFramework = require("CraftingFramework")
local ValueModifier = require("mer.joyOfPainting.services.ValueModifier")
local Refill = require("mer.joyOfPainting.items.Refill")
local meshService = require("mer.joyOfPainting.services.MeshService")
---@class JOP.Palette : JOP.ItemInstance
local Palette = {
    classname = "Palette",
    ---@type JOP.PaletteItem
    paletteItem = nil,
    ---@type tes3reference
    reference = nil,
    ---@type tes3misc
    item = nil,
}
Palette.__index = Palette

--[[
    Register a palette item
]]
---@param e JOP.PaletteItem
function Palette.registerPaletteItem(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:assert(type(e.paintType) == "string", "paintTypes must be a table")
    logger:debug("Registering palette item %s", e.id)
    e = table.copy(e, {})
    e.id = e.id:lower()
    config.paletteItems[e.id] = e
    if e.meshOverride then
        meshService.registerOverride(e.id, e.meshOverride)
    end
    CraftingFramework.Indicator.register{
        objectId = e.id,
        additionalUI = function(indicator, parent)
            local palette = Palette:new{
                reference = indicator.reference,
                item  = indicator.item,
                itemData = indicator.dataHolder --[[@as tes3itemData]],
            }
            if palette then
                palette:doTooltip(parent)
            end
        end,
    }
    if e.paintValue or e.breaks then
        ValueModifier.register{
            objectId = e.id,
            calcValue = function(calcEventData)
                local newPrice = calcEventData.price

                local palette = Palette:new{
                    item = calcEventData.item,
                    itemData = calcEventData.itemData,
                }
                if palette then
                    local remainingRatio = palette:getRemainingUses() / palette:getMaxUses()
                    --if the palette breaks, price decays to 0, otherwise it builds up to paintValue from base
                    if palette.paletteItem.breaks then
                        newPrice = math.floor(calcEventData.price * remainingRatio)
                    else
                        newPrice = math.floor(calcEventData.price + (e.paintValue * remainingRatio))
                    end
                end
                return newPrice
            end
        }
    end
end

---@param e JOP.PaintType
function Palette.registerPaintType(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:assert(type(e.name) == "string", "name must be a string")
    logger:debug("Registering palette type %s", e.id)
    local paintType = table.copy(e, {})
    paintType.id = paintType.id:lower()
    paintType.action = paintType.action or "Paint"
    config.paintTypes[paintType.id] = paintType
end

---@param e JOP.Palette.params
---@return JOP.Palette | nil
function Palette:new(e)
    local instance = common.createItemInstance(e, self, logger)
    instance.paletteItem = config.paletteItems[instance.item.id:lower()]
    if instance.paletteItem == nil then
        logger:debug("%s is not a instance", instance.item.id)
        return nil
    end
    return instance --[[@as JOP.Palette]]
end

---@param ownerRef tes3reference?
function Palette:use(ownerRef)
    if self:getRemainingUses() > 0 then
        logger:debug("Using up paint for %s", self.item.id)
        if not self.data.uses then
            self.data.uses = self.paletteItem.uses
        end
        self.data.uses = self.data.uses - 1
        NodeManager.updateSwitch("paint_palette")
        if self.paletteItem.breaks and self.data.uses == 0 then
            logger:debug("Palette has no more uses, removing")
            if self.reference then
                self.reference:delete()
            elseif ownerRef then
                CraftingFramework.CarryableContainer.removeItem{
                    reference = ownerRef,
                    item = self.item,
                    itemData = self.itemData,
                    playSound = false,
                }
            end
        end
        return true
    end
    logger:debug("Palette has no more uses")
    return false
end

---@return JOP.PaintType
function Palette:getPaintType()
    return config.paintTypes[self.paletteItem.paintType]
end

function Palette:initRefillMenuActivator()
    local paintType = self:getPaintType()

    config.paintTypes[paintType.id].refillMenu = CraftingFramework.MenuActivator:new{
        id = "JOP_RefillPaint_" .. paintType.id,
        name = string.format("Refill %s", paintType.name),
        type = "event",
        defaultFilter = "all",
        defaultShowCategories = false,
        closeCallback = function() end,
        craftButtonText = "Refill",
        showCollapseCategoriesButton = false,
        showCategoriesButton = false,
        showFilterButton = false,
        showSortButton = false,
        recipes = {}
    }
end

function Palette:updateRecipes()
    local paintType = self:getPaintType()
    if not paintType.refillMenu then
        self:initRefillMenuActivator()
    end

    ---@type CraftingFramework.Recipe.data[]
    local recipes = {}
    for _, refill in ipairs(Refill.getRefills(paintType)) do
        logger:debug("Adding %s to refill recipes", refill.recipe.id)
        table.insert(recipes, refill.recipe)
    end
    paintType.refillMenu:registerRecipes(recipes)
end

function Palette.getPaletteToRefill()
    return tes3.player.tempData.jop_paletteToRefill
end

function Palette:setPaletteToRefill()
    tes3.player.tempData.jop_paletteToRefill = self
end

function Palette:openRefillMenu()
    local paintType = self:getPaintType()
    self:updateRecipes()
    self:setPaletteToRefill()
    paintType.refillMenu:openMenu()
end

function Palette:doRefill()
    self.data.uses = self.paletteItem.uses
    NodeManager.updateSwitch("paint_palette")
end

function Palette:getRefills()
    local paintType = self:getPaintType()
    return Refill.getRefills(paintType)
end

function Palette:hasRefillRecipes()
    local refills = self:getRefills()
    return refills ~= nil and #refills > 0
end

---@return number
function Palette:getRemainingUses()
    if not self.data.uses then
        if self.paletteItem.fullByDefault then
            return self.paletteItem.uses
        else
            return 0
        end
    end
    return self.data.uses
end

---@return number
function Palette:getMaxUses()
    return self.paletteItem.uses
end

---@param id string
---@return boolean
function Palette.isPalette(id)
    return config.paletteItems[id:lower()] ~= nil
end

function Palette:doTooltip(parent)
    local labelText = string.format("Uses: %s/%s",
        self:getRemainingUses(),
        self:getMaxUses())
    parent:createLabel{text = labelText}
end

return Palette