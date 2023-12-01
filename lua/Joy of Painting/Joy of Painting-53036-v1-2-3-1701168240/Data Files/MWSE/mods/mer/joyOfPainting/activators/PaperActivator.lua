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

local function paperPaint(reference, artStyleName)
    local painting = Painting:new{
        reference = reference
    }
    painting.data.artStyle = artStyleName

    local canvasConfig = painting:getCanvasConfig()
    if canvasConfig then
        timer.delayOneFrame(function()
            PhotoMenu:new{
                canvasConfig = canvasConfig,
                artStyle = config.artStyles[artStyleName],
                captureCallback = function(e)
                    --set paintingTexture before creating object
                    painting.data.paintingTexture = e.paintingTexture
                    painting.data.location = tes3.player.cell.displayName
                    painting:doPaintAnim()
                end,
                cancelCallback = function()
                    logger:debug("Cancelling painting")
                    tes3.messageBox("You scrape the paint from the canvas.")
                    painting:cleanCanvas()
                end,
                closeCallback = function()
                    --clear painting data from paper
                    painting:clearData()
                end,
                finalCallback = function(e)
                    logger:debug("Creating new object for painting %s", e.paintingName)
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

                    tes3.messageBox("Successfully created %s", newPaintingObject.name)
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

---@param e equipEventData|activateEventData
local function activate(e)
    local painting = Painting:new{
        reference = e.target,
        item = e.item,
        itemData = e.itemData,
    }
    tes3ui.showMessageMenu{
        message = painting.reference.object.name,
        buttons = {
            {
                text = "Draw",
                callback = function()
                    local buttons = {}
                    for _, artStyleData in pairs(config.artStyles) do
                        local artStyle = ArtStyle:new(artStyleData)
                        if not artStyle.requiresEasel then
                            table.insert(buttons, artStyle:getButton(function()
                                paperPaint(painting.reference, artStyle.name)
                            end))
                        end
                    end
                    tes3ui.showMessageMenu{
                        text = "Select Art Style",
                        buttons = buttons,
                        cancels = true
                    }
                end,
            },
            {
                text = "Rotate",
                callback = function()
                    painting:rotate()
                end,
                showRequirements = function()
                    return painting:getRotatedId() ~= nil
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    common.pickUp(painting.reference)
                end,
            }
        },
        cancels = true
    }
end

Activator.registerActivator{
    onActivate = activate,
    isActivatorItem = function(e)
        if e.target and tes3ui.menuMode() then
            logger:debug("Menu mode, skip")
            return false
        end
        --For now, only activate paper when its in the world
        if not e.target then return false end
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