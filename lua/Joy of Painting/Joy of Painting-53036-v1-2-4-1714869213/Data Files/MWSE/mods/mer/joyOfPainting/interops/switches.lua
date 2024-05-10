local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local Palette = require("mer.joyOfPainting.items.Palette")
local PaperMold = require("mer.joyOfPainting.items.PaperMold")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Switches")
---@type JOP.Switch[]
local switches = {
    {
        id = "paint_palette",
        switchName = "SWITCH_PALETTE_PAINT",
        getActiveNode = function(e)
            local palette = Palette:new{reference = e.reference}
            local hasPaint = palette and palette:getRemainingUses() > 0
            return hasPaint and "ON" or "OFF"
        end,
    },
    {
        id = "paper_mold",
        switchName = "SWITCH_PAPER_MOLD",
        getActiveNode = function(e)
            local paperMold = PaperMold:new{reference = e.reference}
            if paperMold == nil then
                logger:warn("paperMold is nil")
                return "OFF"
            end
            if paperMold:hasPulp() then
                return "WET"
            elseif paperMold:hasPaper() then
                return "DRY"
            else
                return "OFF"
            end
        end,
    }
}
event.register(tes3.event.initialized, function()
    for _, switch in ipairs(switches) do
        logger:debug("Registering switch %s", switch.id)
        NodeManager.registerSwitch(switch)
    end
end)