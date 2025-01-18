local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("TileDropper")

local ALPHA_HIGHLIGHT = 0.7
local ALPHA_HOVER = 1.0

---@alias CraftingFramework.TileDropper.isValidTarget.params CraftingFramework.TileDropper.itemInfo
---@alias CraftingFramework.TileDropper.canDrop.params { target: CraftingFramework.TileDropper.itemInfo, held: CraftingFramework.TileDropper.itemInfo }
---@alias CraftingFramework.TileDropper.onDrop.params { reference: tes3reference, target: CraftingFramework.TileDropper.itemInfo, held: CraftingFramework.TileDropper.itemInfo }

---@class (exact) CraftingFramework.TileDropper.itemInfo
---@field item tes3item|tes3misc|tes3weapon
---@field itemData? tes3itemData
---@field count number
---@field tile? tes3inventoryTile

---@class (exact) CraftingFramework.TileDropper.data
---@field name string # The name of the dropper
---@field isValidTarget fun(params: CraftingFramework.TileDropper.isValidTarget.params): boolean # A callback to determine if the tile can be dropped onto. This is checked once when the tile is created.
---@field canDrop fun(params: CraftingFramework.TileDropper.canDrop.params): boolean # A callback to determine if the tile being held can be dropped.
---@field onDrop fun(params: CraftingFramework.TileDropper.onDrop.params) # A callback to run when the item is dropped.
---@field highlightColor? table # The color to highlight the tile with. Defaults to {0.0, 1.0, 0.0} (green)
---@field keepHeldInCursor? boolean # If true, the held item will not be dropped when the tile is clicked.
---@field logger? mwseLogger # A logger to use for this dropper.

---@class CraftingFramework.TileDropper : CraftingFramework.TileDropper.data
local TileDropper = {
    ---@type CraftingFramework.TileDropper[]
    registeredTileDroppers = {}
}

local menuElements = {
    MenuInventory = {
        scrollPane = "MenuInventory_scrollpane",
        propertyObject = "MenuInventory_Thing",
    },
    MenuContents = {
        scrollPane = "MenuContents_scrollpane",
        propertyObject = "MenuContents_Thing",
    },
    MenuBarter = {
        scrollPane = "MenuBarter_scrollpane",
        propertyObject = "MenuBarter_Thing",
    }
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

function TileDropper.resetTile(tile, element)
    local target = {
        item = tile.item,
        itemData = tile.itemData,
        count = tile.count or 1,
        tile = tile
    }
    local highlightDropper = nil
    for _, tileDropper in pairs(TileDropper.registeredTileDroppers) do
        if tileDropper.isValidTarget(target) then
            highlightDropper = tileDropper
        end
    end
    local held = Util.getHeldTile()

    logger:debug("Has highlightDropper: %s", highlightDropper ~= nil)
    logger:debug("Has held: %s", held ~= nil)

    if highlightDropper ~= nil and held ~= nil and highlightDropper.canDrop{ target = target, held = held } then
        logger:debug("Highlighting %s", target.item.id)
        highlightDropper:highlightTile(target, ALPHA_HIGHLIGHT)
    else
        logger:debug("Not highlighting %s", target.item.id)
        TileDropper.removeHighlight(element)
    end
end

function TileDropper.resetTiles()
    for menuId, ids in pairs(menuElements) do
        local menu = tes3ui.findMenu(menuId)
        if menu and menu.visible then
            logger:debug("Resetting tiles in %s", menuId)
            local scrollPane = menu:findChild(ids.scrollPane)
            logger:debug("Found scroll pane %s", scrollPane.id)
            for _, column in ipairs(scrollPane:getContentElement().children) do
                for _, element in ipairs(column.children) do
                    ---@type tes3inventoryTile
                    local tile = element:getPropertyObject(ids.propertyObject, "tes3inventoryTile")
                    if tile then
                        logger:debug("Resetting tile %s", tile.item.id)
                        TileDropper.resetTile(tile, element)
                    end
                end
            end
            menu:updateLayout()
        else
            logger:debug("Menu %s not found or not visible", menuId)
        end
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
        highlightIcon.width = 42
        highlightIcon.height = 42
        highlightIcon.absolutePosAlignX = 0.5
        highlightIcon.absolutePosAlignY = 0.5
        highlightIcon.consumeMouseEvents = false
        highlightIcon.color = self.highlightColor or {0.0, 1.0, 0.0}
    end
    highlightIcon.alpha = alpha
    highlightIcon.visible = true
end

---@param element tes3uiElement
function TileDropper.removeHighlight(element)
    local highlightIcon = element:findChild("CF_TileDropper_Active")
    if highlightIcon then
        highlightIcon.visible = false
    end
end

---@param target CraftingFramework.TileDropper.itemInfo
function TileDropper:tileMouseOverCallback(target)
    self.logger:trace("Mouse over %s", target.item.id)
    local held = Util.getHeldTile()
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
    local held = Util.getHeldTile()
    if held and self.canDrop{ target = target, held = held } then
        self:highlightTile(target, ALPHA_HIGHLIGHT)
    else
        self.removeHighlight(target.tile.element)
    end
end


---@param target CraftingFramework.TileDropper.itemInfo
---@return boolean success
function TileDropper:tileMouseClickCallback(target)
    self.logger:debug("Mouse click on %s", target.item.id)
    local held = Util.getHeldTile()
    if not ( held and self.canDrop{ target = target, held = held }) then
        self.logger:debug("Cannot drop onto %s", target.item.id)
        return false
    end
    self.logger:debug("Dropping %s onto %s", held.item.id, target.item.id)

    --get reference from tile menu source
    local tile = target.tile
    local reference = tes3.player
    local menu = tile and tile.element:getTopLevelMenu()
    if menu and menu.name == "MenuContents" then
        reference = menu:getPropertyObject("MenuContents_ObjectRefr")
    end
    Util.blockNextSound()
    timer.frame.delayOneFrame(function()
        self.onDrop({ target = target, held = held, reference = reference })
        if self.keepHeldInCursor then
            --iterate tiles, find the previously held item, trigger mouseClick
            for _, data in ipairs(TileDropper.getInventoryTiles()) do
                if data.tile.item == held.item and data.tile.itemData == held.itemData then
                    data.element:triggerEvent("mouseClick")
                    TileDropper.resetTiles()
                    break
                end
            end
        end
    end)
    return true
end


---@param target CraftingFramework.TileDropper.itemInfo
function TileDropper:onItemTileUpdate(target)
    local targetIsValid = self.isValidTarget(target)
    if not targetIsValid then return end
    if not target.tile then return end
    if not target.tile.element then return end

    self.logger:debug("Registering tile (%s) for %s", target.item.id, self.name)

    ---mouseOver: highlight tile
    target.tile.element:registerAfter("mouseOver", function()
        self:tileMouseOverCallback(target)
    end)

    --mouseLeave: find and remove rect
    target.tile.element:registerAfter("mouseLeave", function()
        self:tileMouseLeaveCallback(target)
    end)

    --mouseClick: call the onDrop callback
    target.tile.element:registerBefore("mouseClick", function(e)
        self:tileMouseClickCallback(target)
    end)
end

---@param e itemTileUpdatedEventData
event.register("itemTileUpdated", function(e)
    if not e.item then return end
    for _, tileDropper in pairs(TileDropper.registeredTileDroppers) do
        tileDropper:onItemTileUpdate{
            item = e.item,
            itemData = e.itemData,
            count = e.tile.count,
            tile = e.tile
        }
    end
end)

---@param actor tes3reference?
---@return { tile: tes3inventoryTile, element: tes3uiElement }[]
function TileDropper.getInventoryTiles(actor)
    actor = actor or tes3.player
    local tiles = {}
    for menuId, ids in pairs(menuElements) do
        local menu = tes3ui.findMenu(menuId)
        if menu and menu.visible then
            local scrollPane = menu:findChild(ids.scrollPane)
            for _, column in ipairs(scrollPane:getContentElement().children) do
                for _, element in ipairs(column.children) do
                    local tile = element:getPropertyObject(ids.propertyObject, "tes3inventoryTile")
                    if tile then
                        table.insert(tiles, { tile = tile, element = element })
                    end
                end
            end
        end
    end
    return tiles
end





---@param e mouseButtonUpEventData
event.register("mouseButtonUp", function(e)
    if not tes3ui.menuMode() then return end
    if not tes3.player then return end
    if e.button == 0 then
        timer.frame.delayOneFrame(function()timer.frame.delayOneFrame(function()
            logger:debug("Highlighting valid tiles")
            TileDropper.resetTiles()
        end)end)
    end
end)


return TileDropper