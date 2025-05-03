local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Easel")
local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local Painting = require("mer.joyOfPainting.items.Painting")
local PhotoMenu = require("mer.joyOfPainting.services.PhotoMenu")
local ArtStyle = require("mer.joyOfPainting.items.ArtStyle")
local Activator = require("mer.joyOfPainting.services.AnimatedActivator")
local Frame = require("mer.joyOfPainting.items.Frame")
local CraftingFramework = require("CraftingFramework")

---@class JOP.CanvasData : JOP.Painting.data
---@field textureWidth number|nil The width of the painting texture
---@field textureHeight number|nil The height of the painting texture
---@field opened boolean|nil

-- Easel class
---@class JOP.Easel
---@field data JOP.CanvasData
local Easel = {
    classname = "Easel",
    ---@type string
    name = nil,
    ---@type tes3reference
    reference = nil,
    ---@type table
    data = nil,
    ---@type JOP.Painting
    painting = nil,
    --- If true, can be packed up
    ---@type boolean
    doesPack = nil,
    ---@type string
    miscItem = nil,
    ---@type boolean?
    isContainer = nil,
}
Easel.__index = Easel

Easel.animationGroups = {
    packed = {
        group = tes3.animationGroup.idle,
    },
    unpacking = {
        group = tes3.animationGroup.idle2,
        duration = 1.6,
    },
    unpacked = {
        group = tes3.animationGroup.idle3,
    },
    opening = {
        group = tes3.animationGroup.idle4,
        duration = 1.3,
    },
    open = {
        group = tes3.animationGroup.idle5,
    },
    closing = {
        group = tes3.animationGroup.idle6,
        duration = 1.3,
    },
    packing = {
        group = tes3.animationGroup.idle7,
        duration = 1.6,
    },
    openPacking = {
        group = tes3.animationGroup.idle8,
        duration = 2.9,
    },
}

---@param reference tes3reference
---@return JOP.Easel|nil
function Easel:new(reference)
    if not self.isEasel(reference) then return nil end
    local config = Easel.getEaselConfig(reference.object.id)
    local easel = setmetatable(table.copy(config), self)
    easel.name = reference.object.name or "Easel"
    easel.reference = reference
    easel.data = setmetatable({}, {
        __index = function(t, k)
            if not easel.reference.data.joyOfPainting then
                return nil
            end
            return easel.reference.data.joyOfPainting[k]
        end,
        __newindex = function(t, k, v)
            if not easel.reference.data.joyOfPainting then
                easel.reference.data.joyOfPainting = {}
            end
            easel.reference.data.joyOfPainting[k] = v
        end
    })
    easel.painting = Painting:new{ reference = easel.reference }
    return easel
end


---@param e { item: tes3item, itemData: tes3itemData, ownerRef: tes3reference }
function Easel:attachCanvasFromInventory(e)
    if not CraftingFramework.CarryableContainer.findItemStack{ item = e.item, itemData = e.itemData, reference = e.ownerRef } then
        logger:debug("Player does not have canvas %s", e.item.id)
        return
    end
    if e.item then
        self.painting:attachCanvas(e.item, e.itemData)
        self:setClamp()
        --Remove the canvas from the player's inventory
        logger:debug("Removing canvas %s from inventory", e.item.id)
        CraftingFramework.CarryableContainer.removeItem{
            reference = e.ownerRef or tes3.player,
            item = e.item.id,
            itemData = e.itemData,
            count = 1,
            playSound = false,
        }
    else
        logger:debug("No canvas selected")
    end
end

function Easel:addContainerRefToInventory()
    local carryable = self:getCarryableContainer()
    if carryable then
        logger:debug("Adding container ref to inventory")
        tes3.addItem{
            reference = tes3.player,
            item = carryable.item,
            count = 1,
            playSound = false,
        }
    end
end

function Easel:removeContainerRefFromInventory()
    local carryable = self:getCarryableContainer()
    if carryable then
        logger:debug("Removing container ref from inventory")
        tes3.removeItem{
            reference = tes3.player,
            item = carryable.item,
            count = 1,
            playSound = false,
        }
    end
end

--[[
    Opens the inventory select menu to select a canvas to attach to the easel
]]
function Easel:openAttachCanvasMenu()
    timer.delayOneFrame(function()
        CraftingFramework.InventorySelectMenu.open{
            title = "Select a canvas",
            noResultsText = "No canvases found",
            callback = function(e)
                timer.delayOneFrame(function()
                    if e.item then
                        self:attachCanvasFromInventory{
                            item = e.item,
                            itemData = e.itemData,
                            ownerRef = e.actor.reference
                        }
                    end
                end)
            end,
            filter = function(e2)
                local painting = Painting:new{ item = e2.item, itemData = e2.itemData }
                local canvasId = (painting.data.canvasId or e2.item.id):lower()
                local canvasConfig = config.canvases[canvasId]
                if Frame.isFrame(e2.item) then
                    logger:trace("Filtering on frame: %s", e2.item.id)
                    return false
                end
                if not canvasConfig then
                    logger:trace("Filtering on canvas %s: no config", e2.item.id)
                    return false
                end
                if not canvasConfig.requiresEasel then
                    logger:trace("Filtering on canvas %s: does not require easel", e2.item.id)
                    return false
                end
                logger:trace("Filtering on canvas %s", e2.item.id)
                return true
            end,
            noResultsCallback = function()
                tes3.messageBox("You don't have any canvases in your inventory.")
            end,
            additionalContainers = {
                self:getCarryableContainer()
            }
        }
    end)
end

function Easel:getCanvasConfig()
    return config.canvases[self.data.canvasId]
end

---@return tes3reference?
function Easel:getContainerReference()
    if not self.miscItem then return end
    local carryable = self:getCarryableContainer()
    if not carryable then return end
    return carryable:getContainerRef()
end

function Easel:getCarryableContainer()
    if not self.miscItem then return end
    return CraftingFramework.CarryableContainer.getFromItem(tes3.getObject(self.miscItem))
end

---Start painting
---@param artStyle string
function Easel:paint(artStyle)

    self.reference.sceneNode.appCulled = true
    assert(self:getCanvasConfig(), "No canvas config found for canvas " .. self.data.canvasId)
    if self:getCanvasConfig() then
        timer.delayOneFrame(function()
            self:addContainerRefToInventory()
            PhotoMenu:new{
                getCanvasConfig = function()
                    return self:getCanvasConfig()
                end,
                artStyle = config.artStyles[artStyle],
                doRotate = function(_)
                    self:rotateCanvas()
                end,
                captureCallback = function(e)
                    --set paintingTexture before creating object
                    self.data.subjects = e.subjects
                    self.data.paintingTexture = e.paintingTexture
                    self.data.location = e.location
                    self.painting:doPaintAnim()
                    self.reference.sceneNode.appCulled = false
                end,
                closeCallback = function()
                    self.reference.sceneNode.appCulled = false
                    self:removeContainerRefFromInventory()
                end,
                cancelCallback = function()
                    logger:debug("Cancelling painting")
                    tes3.messageBox("You scrape the paint from the canvas.")
                    self.painting:cleanCanvas()
                    self:removeContainerRefFromInventory()
                end,
                finalCallback = function(e)
                    logger:debug("Creating new object for painting %s", e.paintingName)
                    self.data.artStyle = artStyle
                    local newPaintingObject = self.painting:createPaintingObject()
                    self.data.paintingId = newPaintingObject.id
                    self.data.canvasId = self.data.canvasId
                    self.data.paintingName = e.paintingName
                    self.painting:doVisuals()
                    tes3.messageBox("Successfully created %s", newPaintingObject.name)
                    --assert all canvas fields are filled in
                    for _, field in ipairs(Painting.canvasFields) do
                        assert(self.data[field] ~= nil, string.format("Missing field %s", field))
                    end
                    self:removeContainerRefFromInventory()
                end
            }:open()
        end)
    else
        logger:error("No canvas data found for %s", self.data.canvasId)
        return
    end
end

function Easel:rotateCanvas()
    local rotatedId = self.painting:getRotatedId()
    if not rotatedId then
        logger:warn("No rotated canvas found for easel %s with canvas %s",
            self.reference.id, self.data.canvasId)
    end
    self.data.canvasId = rotatedId
    self:setClamp()
    self.painting:doVisuals()
    tes3.playSound{
        reference = self.reference,
        sound = "Item Misc Up",
    }
end

---@return boolean
function Easel:canAttachCanvas()
    return self.data.canvasId == nil
end

function Easel:isPortable()
    return self.miscItem ~= nil
end

---@return boolean
function Easel:hasCanvas()
    return self.data.canvasId ~= nil
end

function Easel:hasPainting()
    return self.data.paintingId ~= nil
end

---@return boolean
function Easel:canPickUp()
    return not self:hasCanvas()
end

function Easel:isOpen()
    if self.doesPack ~= true then
        return true
    end
    return self.data.opened == true
end

function Easel:open()
    if not self.doesPack then
        logger:error("Tried to close an easel that doesn't pack")
        return
    end
    logger:debug("Opening")
    self.data.opened = true
    Activator.playActivatorAnimation{
        reference = self.reference,
        group = self.animationGroups.opening,
        nextAnimation = self.animationGroups.open.group,
        sound = "Wooden Door Open 1",
        duration = 1.3,
    }
end

function Easel:close()
    if not self.doesPack then
        logger:error("Tried to close an easel that doesn't pack")
        return
    end
    logger:debug("Closing")
    self.data.opened = false
    Activator.playActivatorAnimation{
        reference = self.reference,
        group = self.animationGroups.closing,
        nextAnimation = self.animationGroups.unpacked.group,
        sound = "Wooden Door Open 1",
        duration = 1.4,
    }
end

function Easel:pickUp()
    if not self.miscItem then
        logger:error("Tried to pick up an easel that doesn't pack")
        return
    end
    if self:hasCanvas() then
        self:takeCanvas()
    end
    logger:debug("Picking up")

    local function swap()
        logger:debug("Adding %s to inventory and deleting easel", self.miscItem)
        local item = tes3.getObject(self.miscItem) --[[@as tes3clothing]]
        tes3.addItem{
            reference = tes3.player,
            item = item,
            count = 1,
        }
        self.reference:delete()
        --Equip if backpack
        if item.objectType == tes3.objectType.clothing then
            local isEquipped = tes3.getEquippedItem{
                actor = tes3.player,
                objectType = tes3.objectType.clothing,
                slot = 11 ---@diagnostic disable-line
            }
            if not isEquipped then
                logger:debug("Equipping %s", self.miscItem)
                tes3.player.mobile:equip{
                    item = item
                }
                local carryable = self:getCarryableContainer()
                if carryable then carryable:updateStats() end
            end
        end
    end

    if self.doesPack then
        Activator.playActivatorAnimation{
            reference = self.reference,
            group = self.data.opened and self.animationGroups.openPacking or self.animationGroups.packing,
            nextAnimation = self.animationGroups.unpacked.group,
            duration = self.data.opened and 3.6 or 1.4,
            sound = "Wooden Door Open 1",
            callback = swap
        }
    else
        swap()
    end
end

function Easel:setClamp()
    local clampNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.EASEL_CLAMP)
    if not clampNode then return end
    local canvasConfig = config.canvases[self.data.canvasId]
    local offset = 0
    if canvasConfig and canvasConfig.clampOffset then
        offset = canvasConfig.clampOffset
    end
    logger:debug("Setting clamp height to %s", offset)
    local clampNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.EASEL_CLAMP)
    clampNode.translation.y = - offset
    clampNode:update()
end

function Easel:getCurrentAnimation()
    if not self.doesPack then return nil end
    if self.data.opened then
        return self.animationGroups.open.group
    else
        return self.animationGroups.unpacked.group
    end
end

function Easel:takeCanvas()
    self.painting:takeCanvas()
    self:setClamp()
end


----------------------------------------
-- Static Functions --------------------
----------------------------------------

---@param e { id: string, miscItem?: string, doesPack?: boolean, isContainer?: boolean }
function Easel.registerEasel(e)
    logger:assert(type(e.id) == "string", "Easel id must be a string")
    logger:debug("Registering easel %s", e.id)
    config.easels[e.id:lower()] = e
    if e.miscItem then
        config.miscEasels[e.miscItem:lower()] = e
    end
end

---@param reference tes3reference?
function Easel.isEasel(reference)
    if not reference then
        return
    end
    if not reference.object then
        logger:warn("No object on reference")
        return
    end

    return Easel.getEaselConfig(reference.object.id) ~= nil
end


function Easel.getEaselConfig(easelId)
    return config.easels[easelId:lower()]
end

--- Get the easel config from the misc item id
function Easel.getEaselFromMiscId(easelId)
    return config.miscEasels[easelId:lower()]
end



---Check the player's inventory for canvas items
---@param easel JOP.Easel? If provided, the easel will be checked for a canvas (assuming its a container)
---@return boolean
function Easel.playerHasCanvas(easel)
    logger:debug("Checking inventory for canvases")
    ---@type CarryableContainer.getInventory.result[][]
    local inventories = {
        CraftingFramework.CarryableContainer.getInventory()
    }
    if easel and easel.miscItem then
        logger:debug("Checking easel for canvas")
        local containerRef = easel:getContainerReference()
        if containerRef then
            logger:debug("Adding easel inventory to check for canvas")
            table.insert(inventories, CraftingFramework.CarryableContainer.getInventory(containerRef))
        end
    end

    for _, inventory in ipairs(inventories) do
        for _, result in ipairs(inventory) do
            local stack = result.stack
            if config.canvases[stack.object.id:lower()] then
                return true
            end
            if stack.variables then
                for _, variable in ipairs(stack.variables) do
                    if variable
                        and variable.data
                        and variable.data.joyOfPainting
                        and variable.data.joyOfPainting.paintingTexture
                    then
                        return true
                    end
                end
            end
        end
    end

    return false
end

---For cloned easels, retrieve the static id of the misc item
---@param miscId string
---@return string
function Easel.getSavedStaticId(miscId)
    tes3.player.data.jopSavedEaselStatics = tes3.player.data.jopSavedEaselStatics or {}
    return tes3.player.data.jopSavedEaselStatics[miscId:lower()]
end

---Save the static id of a cloned easel
---@param e { miscId: string, staticId: string }
function Easel.saveStaticId(e)
    tes3.player.data.jopSavedEaselStatics = tes3.player.data.jopSavedEaselStatics or {}
    tes3.player.data.jopSavedEaselStatics[e.miscId:lower()] = e.staticId:lower()
end


function Easel.getActivationButtons()
    local buttons =  {
        {
            text = "Open Lid",
            callback = function(e)
                local easel = Easel:new(e.reference)
                return easel and easel:open()
            end,
            showRequirements = function(e)
                local easel = Easel:new(e.reference)
                return easel and easel.doesPack == true and not easel:isOpen()
            end
        },
        {
            text = "Paint",
            callback = function(e)
                local easel = Easel:new(e.reference)
                if not easel then return end

                local buttons = {}
                for _, artStyleData in pairs(config.artStyles) do
                    local artStyle = ArtStyle:new(artStyleData)
                    table.insert(buttons, artStyle:getButton(
                        function() Easel:new(e.reference):paint(artStyle.id) end,
                        easel
                    ))
                end
                tes3ui.showMessageMenu{
                    text = "Select Art Style",
                    buttons = buttons,
                    cancels = true
                }
            end,
            enableRequirements = function(e)
                local easel = Easel:new(e.reference)
                return easel and easel:hasCanvas() and not easel:hasPainting()
            end,
            showRequirements = function(e)
                local easel = Easel:new(e.reference)
                return easel and easel:isOpen()
            end,
            tooltipDisabled = function(e)
                local easel = Easel:new(e.reference)
                local text = ""
                if not easel then
                    text = "This is not an easel."
                elseif  not easel:hasCanvas() then
                    text = "Attach a canvas to the easel first."
                elseif easel:hasPainting() then
                    text = "The easel already has a painting."
                end
                return {
                    text = text
                }
            end
        },
        {
            text = "View Painting",
            callback = function(e)
                timer.delayOneFrame(function()
                    Painting:new{
                        reference = e.reference,
                        item = e.item,
                        itemData = e.itemData,
                    }:paintingMenu()
                end)
            end,
            showRequirements = function(e)
                local easel = Easel:new(e.reference)
                return easel and easel:hasPainting()
            end,
        },
        {
            text = "Rotate Canvas",
            callback = function(e)
                Easel:new(e.reference):rotateCanvas()
            end,
            showRequirements = function(e)
                local painting = Painting:new{
                    reference = e.reference ---@type any
                }
                return painting:isRotatable()
            end,
        },
        {
            text = "Attach Canvas",
            callback = function(e)
                Easel:new(e.reference):openAttachCanvasMenu()
            end,
            showRequirements = function(e)
                local easel = Easel:new(e.reference)
                return easel and easel:isOpen() and easel:canAttachCanvas()
            end,
            enableRequirements = function(e)
                local easel = Easel:new(e.reference)
                return Easel.playerHasCanvas(easel)
            end,
            tooltipDisabled = function(e)
                local text = ""
                if not Easel.playerHasCanvas() then
                    text = "You do not have any canvases."
                end
                return {
                    text = text
                }
            end
        },
        {
            text = "Take Canvas",
            callback = function(e)
                Easel:new(e.reference):takeCanvas()

            end,
            showRequirements =  function(e)
                local easel = Easel:new(e.reference)
                return easel and easel:hasCanvas() and not easel:hasPainting()
            end,
        },
        {
            text = "Take Painting",
            callback = function(e)
                Easel:new(e.reference):takeCanvas()
            end,
            showRequirements = function(e)
                local easel = Easel:new(e.reference)
                return easel and easel:hasPainting()
            end,
        },
        {
            text = "Open",
            callback = function(e)
                timer.delayOneFrame(function()
                    logger:debug("Opening easel")
                    local carryable = Easel:new(e.reference):getCarryableContainer()
                    if carryable then
                        carryable:openFromInventory()
                    else
                        logger:error("No carryable container found")
                    end
                end)
            end,
            showRequirements = function(e)
                local easel = Easel:new(e.reference)
                return easel and easel:getCarryableContainer() ~= nil
            end
        },
        {
            text = "Position",
            callback = function(e)
                ---@diagnostic disable-next-line
                common.positioner{
                    reference = e.reference,
                }
            end,
            showRequirements = function(e)
                local easel = Easel:new(e.reference)
                return easel and not easel.reference.data.crafted
            end
        },
        {
            text = "Close Lid",
            callback = function(e)
                local easel = Easel:new(e.reference)
                if not easel then return end
                easel:close()
            end,
            showRequirements = function(e)
                local easel = Easel:new(e.reference)
                return easel and easel.doesPack and easel:isOpen()
                    and not easel:hasCanvas()
            end
        },
        {
            text = "Pick Up",
            callback = function(e)
                local easel = Easel:new(e.reference)
                if not easel then return end
                easel:pickUp()
            end,
            showRequirements = function(e)
                local easel = Easel:new(e.reference)
                return easel and not easel.reference.data.crafted
            end
        }
    }
    return buttons
end


return Easel