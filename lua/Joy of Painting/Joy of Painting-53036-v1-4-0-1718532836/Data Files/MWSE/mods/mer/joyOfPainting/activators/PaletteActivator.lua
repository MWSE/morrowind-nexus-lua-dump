local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaletteActivator")
local Activator = require("mer.joyOfPainting.services.AnimatedActivator")
local Palette = require("mer.joyOfPainting.items.Palette")

local function activate(e)
    logger:debug("Activating palette")
    local palette = Palette:new{
        reference = e.target,
        item = e.item,
        itemData = e.itemData,
    }
    if palette == nil then
        logger:error("Palette is nil")
        return
    end
    local refills = palette:getRefills()
    if not refills then
        logger:warn("No refills found for palette %s", palette and palette.item.id)
        return
    end

    tes3ui.showMessageMenu{
        message = palette.item.name,
        buttons = {
            {
                text = "Refill",
                callback = function()
                    palette:openRefillMenu()
                end,
                enableRequirements = function()
                    return (palette:getRemainingUses() < palette:getMaxUses())
                end,
                tooltipDisabled = function()
                    if not (palette:getRemainingUses() < palette:getMaxUses()) then
                        return { text = "This palette is already full." }
                    end
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    common.pickUp(palette.reference)
                end,
                showRequirements = function()
                    if palette.reference then
                        return true
                    end
                    return false
                end
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
        local palette = Palette:new{
            reference = e.target,
            item = e.item,
            itemData = e.itemData,
        }
        return palette and palette:hasRefillRecipes()
    end
}