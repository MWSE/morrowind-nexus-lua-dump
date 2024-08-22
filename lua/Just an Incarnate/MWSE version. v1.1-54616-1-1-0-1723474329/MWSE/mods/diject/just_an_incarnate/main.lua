local mcm = include("diject.just_an_incarnate.mcm")

local espName = "Just An Incarnate.ESP"

--- @param e initializedEventData
local function initializedCallback(e)
    if not tes3.isModActive(espName) then
        mcm.modData.hidden = true ---@diagnostic disable-line: inject-field
        return
    end
    include("diject.just_an_incarnate.entry")
    include("diject.just_an_incarnate.player").init()
end
event.register(tes3.event.initialized, initializedCallback)