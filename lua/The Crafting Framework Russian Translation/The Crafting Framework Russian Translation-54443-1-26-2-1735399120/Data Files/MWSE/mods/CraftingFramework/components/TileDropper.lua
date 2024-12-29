local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("TileDropper")
local defaultHighlightColor = {200/255, 255/255, 255/255}

---@alias CraftingFramework.TileDropper.isValidTarget.params CraftingFramework.TileDropper.itemInfo
---@alias CraftingFramework.TileDropper.canDrop.params { target: CraftingFramework.TileDropper.itemInfo, held: CraftingFramework.TileDropper.itemInfo }
---@alias CraftingFramework.TileDropper.onDrop.params { target: CraftingFramework.TileDropper.itemInfo, held: CraftingFramework.TileDropper.itemInfo }

---@class (exact) CraftingFramework.TileDropper.itemInfo
---@field item tes3item
---@field itemData? tes3itemData
---@field count number

---@class (exact) CraftingFramework.TileDropper.data
---@field name string # The name of the dropper
---@field isValidTarget fun(params: CraftingFramework.TileDropper.isValidTarget.params): boolean # A callback to determine if the tile can be dropped onto. This is checked once when the tile is created.
---@field canDrop fun(params: CraftingFramework.TileDropper.canDrop.params): boolean # A callback to determine if the tile being held can be dropped.
---@field onDrop fun(params: CraftingFramework.TileDropper.onDrop.params) # A callback to run when the item is dropped.
---@field highlightColor? number[] # The color to highlight the tile when it is a valid target.
---@field logger? mwseLogger # A logger to use for this dropper.

---@class CraftingFramework.TileDropper : CraftingFramework.TileDropper.data
local TileDropper = {
    ---@type CraftingFramework.TileDropper[]
    registeredTileDroppers = {}
}

---Registers a new TileDropper.
---@param data CraftingFramework.TileDropper.data
---@return CraftingFramework.TileDropper
function TileDropper.register(data)
    local tileDropper = TileDropper:new(data)
    TileDropper.registeredTileDroppers[tileDropper] = tileDropper
    logger:debug("Registered TileDropper %s", tileDropper.name)
    return tileDropper
end

---Creates a new TileDropper
---@param data CraftingFramework.TileDropper.data
---@return CraftingFramework.TileDropper
function TileDropper:new(data)
    data = table.copy(data)
    data.logger = data.logger or Util.createLogger("TileDropper: " .. data.name)
    data.highlightColor = data.highlightColor or defaultHighlightColor
    logger:assert(type(data.name) == "string", "data.dropperName is required")
    logger:assert(type(data.isValidTarget) == "function", "data.isValidTarget is required")
    logger:assert(type(data.canDrop) == "function", "data.canDrop is required")
    logger:assert(type(data.onDrop) == "function", "data.onDrop is required")
    setmetatable(data, self)
    self.__index = self
    return data
end


---@param e itemTileUpdatedEventData
function TileDropper:onItemTileUpdate(e)
    local targetIsValid = self.isValidTarget{
        item = e.item,
        itemData = e.itemData,
        count = e.tile.count or 1
    }
    if targetIsValid then
        self.logger:debug("Registering tile (%s) for %s", e.item.id, self.name)
        ---@type CraftingFramework.TileDropper.itemInfo
        local target = {
            item = e.item,
            itemData = e.itemData,
            count = e.tile.count or 1
        }
        ---@param mouseOverEventData tes3uiEventData
        e.tile.element:registerAfter("mouseOver", function(mouseOverEventData)
            self.logger:trace("Mouse over %s", e.item.id)
            local cursorIcon = tes3ui.findHelpLayerMenu("CursorIcon")
            ---@type CraftingFramework.TileDropper.itemInfo
            local held = cursorIcon and cursorIcon:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
            if not held then
                self.logger:trace("No held item")
                return
            end
            if not self.canDrop{ target = target, held = held } then
                self.logger:trace("Cannot drop %s onto %s", held.item.id, e.item.id)
                return
            end
            self.logger:trace("Activating mouse-over for %s", e.item.id)
            --Set tile background color
            local rect = e.tile.element:createRect{
                id = "CF_TileDropper_Active",
                color = self.highlightColor,
            }
            rect.width = 32
            rect.height = 32
            rect.alpha = 0.4
            rect.absolutePosAlignX = 0.5
            rect.absolutePosAlignY = 0.5
            rect.consumeMouseEvents = false
            e.tile.element:reorderChildren(0, -1, 1)
            e.tile.element:updateLayout()
        end)

        --mouseLeave: find and remove rect
        e.tile.element:registerAfter("mouseLeave", function(mouseLeaveEventData)
            self.logger:trace("Mouse leave %s", e.item.id)
            local rect = e.tile.element:findChild("CF_TileDropper_Active")
            if rect then
                rect:destroy()
            end
        end)

        e.tile.element:registerBefore("mouseClick", function(mouseClickEventData)
            self.logger:trace("Mouse click on %s", e.item.id)
            local cursor = tes3ui.findHelpLayerMenu("CursorIcon")
            ---@type CraftingFramework.TileDropper.itemInfo
            local held = cursor and cursor:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
            if not ( held and self.canDrop{ target = target, held = held }) then
                return
            end
            self.logger:debug("Dropping %s onto %s", held.item.id, target.item.id)
            timer.frame.delayOneFrame(function()
                self.onDrop({ target = target, held = held })
            end)
        end)
    end
end

---@param e itemTileUpdatedEventData
event.register("itemTileUpdated", function(e)
    if not e.item then return end
    for _, tileDropper in pairs(TileDropper.registeredTileDroppers) do
        tileDropper:onItemTileUpdate(e)
    end
end)


return TileDropper