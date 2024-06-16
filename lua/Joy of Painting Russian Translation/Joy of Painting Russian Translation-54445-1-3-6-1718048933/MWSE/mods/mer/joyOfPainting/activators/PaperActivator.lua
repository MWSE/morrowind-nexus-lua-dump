--[[
    Activate a quill with a piece of paper and inkwell in your inventory to begin sketching
]]
local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaperActivator")
local Painting = require("mer.joyOfPainting.items.Painting")
local ArtStyle = require("mer.joyOfPainting.items.ArtStyle")
local PhotoMenu = require("mer.joyOfPainting.services.PhotoMenu")
local Activator = require("mer.joyOfPainting.services.AnimatedActivator")

---@param painting JOP.Painting
---@param artstyle JOP.ArtStyle
local function inventoryPaint(painting, artstyle)
    if painting:getCanvasConfig() then
        timer.delayOneFrame(function()
            PhotoMenu:new{
                getCanvasConfig = function()
                    return painting:getCanvasConfig()
                end,
                artStyle = config.artStyles[artstyle.name],
                captureCallback = function(e)
                    painting.data.paintingTexture = e.paintingTexture
                    painting.data.location = tes3.player.cell.displayName
                end,
                doRotate = function(photoMenu)
                    painting:rotate()
                    painting = Painting:new{
                        item = painting.item,
                        itemData = painting.dataHolder,
                    }
                    photoMenu.painting = painting
                end,
                closeCallback = function()
                    --clear painting data from paper
                    painting:clearData()
                end,
                finalCallback = function(e)
                    logger:debug("Creating new object for painting %s", e.paintingName)
                    painting.data.artStyle = artstyle.name
                    local newPaintingObject = painting:createPaintingObject()
                    tes3.removeItem{
                        reference = tes3.player,
                        item = painting.item,
                        itemData = painting.dataHolder,
                        playSound = false,
                    }
                    tes3.addItem{
                        reference = tes3.player,
                        item = newPaintingObject,
                        updateGUI = true,
                    }
                    local itemData = tes3.addItemData{
                        to = tes3.player,
                        item = newPaintingObject,
                    }

                    itemData.data.joyOfPainting = {}
                    local paperPainting = Painting:new{
                        item = painting.item,
                        itemData = itemData,
                    }
                    for _, field in ipairs(Painting.canvasFields) do
                        paperPainting.data[field] = painting.data[field]
                    end

                    paperPainting.data.paintingId = newPaintingObject.id
                    paperPainting.data.canvasId = painting.item.id:lower()
                    paperPainting.data.paintingName = e.paintingName

                    tes3.messageBox("Вы создали %s", newPaintingObject.name)
                    --assert all canvasConfig fields are filled in
                    for _, field in ipairs(Painting.canvasFields) do
                        assert(paperPainting.data[field] ~= nil, string.format("Missing field %s", field))
                    end

                end
            }:open()
        end)
    else
        logger:error("No canvas data found for %s", painting.data.canvasId)
        return
    end
end


---@param painting JOP.Painting
---@param artstyle JOP.ArtStyle
local function paperPaint(painting, artstyle)

    if painting:getCanvasConfig() then
        timer.delayOneFrame(function()
            PhotoMenu:new{
                getCanvasConfig = function()
                    return painting:getCanvasConfig()
                end,
                doRotate = function(photoMenu)
                    local newRef = painting:rotate()
                    painting = Painting:new{
                        reference = newRef
                    }
                    photoMenu.painting = painting
                end,
                artStyle = config.artStyles[artstyle.name],
                captureCallback = function(e)
                    --set paintingTexture before creating object
                    painting.data.paintingTexture = e.paintingTexture
                    painting.data.location = tes3.player.cell.displayName
                    painting:doPaintAnim()
                end,
                cancelCallback = function()
                    logger:debug("Cancelling painting")
                    tes3.messageBox("Вы соскребаете краску с холста")
                    painting:cleanCanvas()
                end,
                closeCallback = function()
                    --clear painting data from paper
                    painting:clearData()
                end,
                finalCallback = function(e)
                    logger:debug("Creating new object for painting %s", e.paintingName)
                    painting.data.artStyle = artstyle.name
                    local newPaintingObject = painting:createPaintingObject()
                    local newPaper = tes3.createReference{
                        object = newPaintingObject,
                        position = painting.reference.position,
                        orientation = painting.reference.orientation,
                        cell = painting.reference.cell,
                        scale = painting.reference.scale,
                    }
                    newPaper.data.joyOfPainting = {}
                    local paperPainting = Painting:new{
                        reference = newPaper
                    }
                    for _, field in ipairs(Painting.canvasFields) do
                        paperPainting.data[field] = painting.data[field]
                    end
                    paperPainting.data.paintingId = newPaintingObject.id
                    paperPainting.data.canvasId = painting.reference.object.id:lower()
                    paperPainting.data.paintingName = e.paintingName
                    paperPainting:doVisuals()

                    tes3.messageBox("Вы создали %s", newPaintingObject.name)
                    --assert all canvasConfig fields are filled in
                    for _, field in ipairs(Painting.canvasFields) do
                        assert(paperPainting.data[field] ~= nil, string.format("Missing field %s", field))
                    end
                    painting.reference:delete()
                end
            }:open()
        end)
    else
        logger:error("No canvas data found for %s", painting.data.canvasId)
        return
    end
end

---@param e equipEventData
local function equip(e)
    local painting = Painting:new{
        item = e.item,
        itemData = e.itemData,
    }
    tes3ui.showMessageMenu{
        message = painting.item.name,
        buttons = {
            {
                text = "Рисовать",
                callback = function()
                    local buttons = {}
                    for _, artStyleData in pairs(config.artStyles) do
                        local artStyle = ArtStyle:new(artStyleData)
                        if not artStyle.requiresEasel then
                            table.insert(buttons, artStyle:getButton(function()
                                inventoryPaint(painting, artStyle)
                            end))
                        end
                    end
                    tes3ui.showMessageMenu{
                        text = "Выберите стиль",
                        buttons = buttons,
                        cancels = true
                    }
                end
            },
            {
                text = "Повернуть",
                callback = function()
                    painting:rotate()
                end,
                showRequirements = function()
                    return painting:getRotatedId() ~= nil
                end
            },

        },
        cancels = true
    }
end

---@param e activateEventData
local function activate(e)
    local painting = Painting:new{
        reference = e.target,
    }
    tes3ui.showMessageMenu{
        message = painting.reference.object.name,
        buttons = {
            {
                text = "Рисовать",
                callback = function()
                    local buttons = {}
                    for _, artStyleData in pairs(config.artStyles) do
                        local artStyle = ArtStyle:new(artStyleData)
                        if not artStyle.requiresEasel then
                            table.insert(buttons, artStyle:getButton(function()
                                paperPaint(painting, artStyle)
                            end))
                        end
                    end
                    tes3ui.showMessageMenu{
                        text = "Выберите стиль",
                        buttons = buttons,
                        cancels = true
                    }
                end,
            },
            {
                text = "Повернуть",
                callback = function()
                    painting:rotate()
                end,
                showRequirements = function()
                    return painting:getRotatedId() ~= nil
                end
            },
            {
                text = "Убрать",
                callback = function()
                    common.pickUp(painting.reference)
                end,
            }
        },
        cancels = true
    }
end

Activator.registerActivator{
    onActivate = function(e)
        if e.target then
            activate(e)
        else
            equip(e)
        end
    end,
    isActivatorItem = function(e)
        -- if e.target and tes3ui.menuMode() then
        --     logger:debug("Menu mode, skip")
        --     return false
        -- end
        -- --For now, only activate paper when its in the world
        -- if not e.target then return false end
        local painting = Painting:new{
            reference = e.target,
            item = e.item,
            itemData = e.itemData,
        }
        local canvasConfig = painting:getCanvasConfig()
        if canvasConfig and not canvasConfig.requiresEasel then
            return true
        end
        return false
    end,
    blockStackActivate = true
}