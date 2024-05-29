local mcm = include("diject.remains_of_the_fallen.mcm")

local espName = "Remains of the Fallen.ESP"

--- @param e initializedEventData
local function initializedCallback(e)
    if not tes3.isModActive(espName) then
        mcm.modData.hidden = true ---@diagnostic disable-line: inject-field
        return
    end
    include("diject.remains_of_the_fallen.entry")
end
event.register(tes3.event.initialized, initializedCallback)