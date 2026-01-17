--[[
    Controller for updating the visuals of paintings and easels
]]
local Painting = require("mer.joyOfPainting.items.Painting")
local Easel = require("mer.joyOfPainting.items.Easel")
local ReferenceManager = require("CraftingFramework").ReferenceManager
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("PaintingVisuals")


ReferenceManager:new{
    id = "painting",
    requirements = function(_, reference)
        return Painting:new{
            reference = reference
        }:hasCanvasData()
    end,
    onActivated = function(_, reference)
        logger:debug("Painting OnActive ref.object.id: %s", reference.object.id)
        local painting =  Painting:new{
            reference = reference
        }
        --Attach canvas then add paint to canvas
        if painting:hasCanvasData() then
            painting:doVisuals()
        end

        local easel = Easel:new(reference)
        if easel then
            if easel.doesPack then
                logger:debug("Setting clamp for %s", easel.reference.id)
                easel:setClamp()
            end
        end
    end
}