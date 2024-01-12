local common = require("mer.skoomaesthesia.common")
local logger = common.createLogger("PipeController")
local config = require('mer.skoomaesthesia.config')
local PipeService = require('mer.skoomaesthesia.services.PipeService')
local ItemService = require('mer.skoomaesthesia.services.ItemService')

local function onEquip(e)
    if not config.mcm.enableSkoomaPipe then return end
    if e.reference ~= tes3.player then return end
    if config.pipeAnimating then return end --in the middle of smoking already
    if ItemService.isPipe(e.item) then
        logger:debug("Equipped pipe: %s", e.item.id)
        if tes3ui.menuMode() then
            logger:debug("Menu mode, show pipe menu")
            PipeService.showPipeMenu({ object = e.item })
        else
            logger:debug("Not menu mode, smoke skooma")
            PipeService.smokeSkooma({ object = e.item})
        end
        return false
    end
end
event.register("equip", onEquip, { priority = 50 })

local function onActivatePipe(e)
    if not config.mcm.enableSkoomaPipe then return end
    if tes3ui.menuMode() then return end
    if e.activator ~= tes3.player then return end
    if config.pipeAnimating then return end --in the middle of smoking already
    if ItemService.isPipe(e.target.baseObject) then
        logger:debug("Activated pipe: %s", e.target.baseObject.id)
        if PipeService.skipActivatePipe then
            PipeService.skipActivatePipe = nil
        else
            logger:debug("Not skipping, show pipe menu")
            local pipeRef = e.target
            PipeService.showPipeMenu({ reference = pipeRef })
            return false
        end
    end
end
event.register("activate", onActivatePipe, { priority = 50 })