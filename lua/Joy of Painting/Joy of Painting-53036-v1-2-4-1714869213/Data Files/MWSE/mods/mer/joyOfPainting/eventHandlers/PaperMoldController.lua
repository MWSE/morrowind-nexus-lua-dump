local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaperMoldController")
local PaperMold = require("mer.joyOfPainting.items.PaperMold")
local ReferenceManager = require("mer.joyOfPainting.services.ReferenceManager")

local INTERVAL = 0.005
---@param e simulateEventData
local function onSimulate(e)
    tes3.player.tempData.jopLastPaperMoldCheck = tes3.player.tempData.jopLastPaperMoldCheck or e.timestamp
    local lastCheck = tes3.player.tempData.jopLastPaperMoldCheck
    if e.timestamp - lastCheck > INTERVAL then
        tes3.player.tempData.jopLastPaperMoldCheck = e.timestamp
        ReferenceManager.iterateReferences("paper_mold", function(reference)
            local paperMold = PaperMold:new{reference = reference}
            if paperMold then
                paperMold:processMold(e.timestamp)
            end
        end)
    end
end

event.register("simulate", onSimulate)