local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("SketchbookActivator")
local Sketchbook = require("mer.joyOfPainting.items.Sketchbook")
local Activator = require("mer.joyOfPainting.services.AnimatedActivator")
---@param e equipEventData|activateEventData
local function activate(e)
    logger:debug("Activating sketchbook")
    local reference = e.target
    local item
    local itemData
    if not e.target then
        item = e.item
        itemData = e.itemData
    end
    local sketchbook = Sketchbook:new{
        reference = reference,
        item = item,
        itemData = itemData,
    }
    sketchbook:activate()
end

Activator.registerActivator{
    onActivate = activate,
    isActivatorItem = function(e)
        if e.target and tes3ui.menuMode() then
            logger:debug("Menu mode, skip")
            return false
        end
        return e.object and Sketchbook.isSketchbook(e.object.id)
    end,
    blockStackActivate = true
}