--[[
    Controller for updating the visuals of paintings and easels
]]
local Painting = require("mer.joyOfPainting.items.Painting")
local Easel = require("mer.joyOfPainting.items.Easel")
local Frame = require("mer.joyOfPainting.items.Frame")
local ReferenceManager = require("mer.joyOfPainting.services.ReferenceManager")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("PaintingVisuals")

ReferenceManager.registerReferenceController{
    id = "painting",
    requirements = function(_, reference)
        return Painting:new{
            reference = reference
        }:hasCanvasData()
    end,
    onActive = function(_, reference)
        logger:debug("Painting OnActive")
        local painting =  Painting:new{
            reference = reference
        }
        --Attach canvas then add paint to canvas
        if painting:hasCanvasData() then
            painting:doVisuals()
        end

        local easel = Easel:new(reference)
        if easel and easel.doesPack then
            logger:debug("Easel %s does pack", easel.reference.id)
            easel:setClamp()
        end
    end
}