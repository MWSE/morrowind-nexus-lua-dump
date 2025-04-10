local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("tileDrop")
local CraftingFramework = require("CraftingFramework")
local TileDropper = CraftingFramework.TileDropper

local Painting = require("mer.joyOfPainting.items.Painting")
local Sketchbook = require("mer.joyOfPainting.items.Sketchbook")
TileDropper.register{
    name = "Sketchbook",
    logger = logger,
    isValidTarget = function(e)
        return Sketchbook.isSketchbook(e.item.id)
    end,
    canDrop = function(e)
        local painting = Painting:new{
            item = e.held.item,
            itemData = e.held.itemData,
        }
        return painting and painting:isSketch()
    end,
    onDrop = function(e)
        local sketchbook = Sketchbook:new{
            item = e.target.item,
            itemData = e.target.itemData,
        }
        if not sketchbook then return end
        sketchbook:appendSketch{
            item = e.held.item,
            itemData = e.held.itemData,
            showMenu = false
        }
    end
}