local config = require('mer.skoomaesthesia.config')
local PipeService = require('mer.skoomaesthesia.services.PipeService')

local function onEquip(e)
    if not config.mcm.enableSkoomaPipe then return end
    if e.reference ~= tes3.player then return end
    if config.pipeAnimating then return end --in the middle of smoking already
    -- if config.static.moonSugarIds[e.item.id:lower()] and not config.skipEquip then
    --     tes3.messageBox("Requires a Skooma Pipe.")
    --     return false
    -- end

    if config.static.pipeIds[e.item.id:lower()] then
        if tes3ui.menuMode() then
            PipeService.showPipeMenu({ object = e.item })
        else
            PipeService.smokeSkooma({ object = e.item})
        end
        
        return false
    end
end
event.register("equip", onEquip, { priority = -50 })


local function onActivatePipe(e)
    if not config.mcm.enableSkoomaPipe then return end
    if tes3ui.menuMode() then return end
    if e.activator ~= tes3.player then return end
    if config.pipeAnimating then return end --in the middle of smoking already

    if config.static.pipeIds[e.target.baseObject.id:lower()] then
        if PipeService.skipActivatePipe then
            PipeService.skipActivatePipe = nil
        else
            local pipeRef = e.target
            PipeService.showPipeMenu({ reference = pipeRef })
            return false
        end
    end
end
event.register("activate", onActivatePipe, { priority = -50 })