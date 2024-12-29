local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("TileDropper")

local ALPHA_HIGHLIGHT = 0.5
local ALPHA_HOVER = 1.0

---@alias CraftingFramework.TileDropper.isValidTarget.params CraftingFramework.TileDropper.itemInfo
---@alias CraftingFramework.TileDropper.canDrop.params { target: CraftingFramework.TileDropper.itemInfo, held: CraftingFramework.TileDropper.itemInfo }
---@alias CraftingFramework.TileDropper.onDrop.params { target: CraftingFramework.TileDropper.itemInfo, held: CraftingFramework.TileDropper.itemInfo }

---@class (exact) CraftingFramework.TileDropper.itemInfo
---@field item tes3item
---@field itemData? tes3itemData
---@field count number
---@field tile? tes3inventoryTile

---@class (exact) CraftingFramework.TileDropper.data
---@field name string # The name of the dropper
---@field isValidTarget fun(params: CraftingFramework.TileDropper.isValidTarget.params): boolean # A callback to determine if the tile can be dropped onto. This is checked once when the tile is created.
---@field canDrop fun(params: CraftingFramework.TileDropper.canDrop.params): boolean # A callback to determine if the tile being held can be dropped.
---@field onDrop fun(params: CraftingFramework.TileDropper.onDrop.params) # A callback to run when the item is dropped.
---@field highlightColor? table # The color to highlight the tile with. Defaults to {0.0, 1.0, 0.0} (green)
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
    logger:assert(type(data.name) == "string", "data.dropperName is required")
    logger:assert(type(data.isValidTarget) == "function", "data.isValidTarget is required")
    logger:assert(type(data.canDrop) == "function", "data.canDrop is required")
    logger:assert(type(data.onDrop) == "function", "data.onDrop is required")
    setmetatable(data, self)
    self.__index = self
    return data
end

---@return CraftingFramework.TileDropper.itemInfo?
local function getHeldTile()
    local cursorIcon = tes3ui.findHelpLayerMenu("CursorIcon")
    local tile = cursorIcon and cursorIcon:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
    if tile then
        return {
            item = tile and tile.item,
            itemData = tile and tile.itemData,
            count = tile and tile.count or 1,
            tile = tile
        }
    end
end

---@param target CraftingFramework.TileDropper.itemInfo
---@param alpha number
function TileDropper:highlightTile(target, alpha)
    local highlightIcon = target.tile.element:findChild("CF_TileDropper_Active")
    if not highlightIcon then
        highlightIcon = target.tile.element:createImage{
            id = "CF_TileDropper_Active",
            path = "icons\\craftingFramework\\highlight.dds",
        }
        highlightIcon.scaleMode = true
        highlightIcon.width = 34
        highlightIcon.height = 34
        highlightIcon.absolutePosAlignX = 0.5
        highlightIcon.absolutePosAlignY = 0.5
        highlightIcon.consumeMouseEvents = false
        highlightIcon.color = self.highlightColor or {0.0, 1.0, 0.0}
    end
    highlightIcon.alpha = alpha
end

function TileDropper.removeHighlight(element)
    local highlightIcon = element:findChild("CF_TileDropper_Active")
    if highlightIcon then
        highlightIcon:destroy()
    end
end




---@param target CraftingFramework.TileDropper.itemInfo
function TileDropper:tileMouseOverCallback(target)
    self.logger:trace("Mouse over %s", target.item.id)
    local held = getHeldTile()
    if not held then
        self.logger:trace("No held item")
        return
    end
    if not self.canDrop{ target = target, held = held } then
        self.logger:trace("Cannot drop %s onto %s", held.item.id, target.item.id)
        return
    end
    self.logger:trace("Activating mouse-over for %s", target.item.id)
    --Set tile background color
    self:highlightTile(target, ALPHA_HOVER)
end

---@param target CraftingFramework.TileDropper.itemInfo
function TileDropper:tileMouseLeaveCallback(target)
    self.logger:trace("Mouse leave %s", target.item.id)
    local held = getHeldTile()
    if held then
        self:highlightTile(target, ALPHA_HIGHLIGHT)
    else
        self.removeHighlight(target.tile.element)
    end
end

---@param target CraftingFramework.TileDropper.itemInfo
function TileDropper:tileMouseClickCallback(target)
    self.logger:trace("Mouse click on %s", target.item.id)
    local held = getHeldTile()
    if not ( held and self.canDrop{ target = target, held = held }) then
        return
    end
    self.logger:debug("Dropping %s onto %s", held.item.id, target.item.id)
    timer.frame.delayOneFrame(function()
        self.onDrop({ target = target, held = held })
    end)
end


---@param e itemTileUpdatedEventData
function TileDropper:onItemTileUpdate(e)
    ---@type CraftingFramework.TileDropper.itemInfo
    local target = {
        item = e.item,
        itemData = e.itemData,
        count = e.tile.count or 1,
        tile = e.tile
    }
    local targetIsValid = self.isValidTarget(target)
    if not targetIsValid then return end

    self.logger:debug("Registering tile (%s) for %s", e.item.id, self.name)

    ---mouseOver: highlight tile
    e.tile.element:registerAfter("mouseOver", function()
        self:tileMouseOverCallback(target)
    end)

    --mouseLeave: find and remove rect
    e.tile.element:registerAfter("mouseLeave", function()
        self:tileMouseLeaveCallback(target)
    end)

    --mouseClick: call the onDrop callback
    e.tile.element:registerBefore("mouseClick", function()
        self:tileMouseClickCallback(target)
    end)

    timer.frame.delayOneFrame(function()    --If a valid item is being held, highlight the tile with 20% alpha
        local held = getHeldTile()
        if held and self.canDrop{ target = target, held = held } then
            self:highlightTile(target, ALPHA_HIGHLIGHT)
        else
            self.removeHighlight(target.tile.element)
        end
    end)
end

---@param e itemTileUpdatedEventData
event.register("itemTileUpdated", function(e)
    if not e.item then return end
    for _, tileDropper in pairs(TileDropper.registeredTileDroppers) do
        tileDropper:onItemTileUpdate(e)
    end
    local held = getHeldTile()
    if held then
        --When the held tile is destroyed, remove all highlights
        if not held.tile.element:getLuaData("CF_TileDropper_Held_registered") then
            logger:trace("Registering held tile event data")
            held.tile.element:setLuaData("CF_TileDropper_Held_registered", true)
            held.tile.element:registerAfter("destroy", function()
                logger:trace("Held tile destroyed, removing highlights")
                local inventoryMenu = tes3ui.findMenu("MenuInventory")
                if not inventoryMenu then return end
                local scrollPane = inventoryMenu:findChild(tes3ui.registerID("MenuInventory_scrollpane"))
                for _, column in ipairs(scrollPane.children) do
                    for _, element in ipairs(column.children) do
                        TileDropper.removeHighlight(element)
                    end
                end
            end)
        end
    end
end)


return TileDropper