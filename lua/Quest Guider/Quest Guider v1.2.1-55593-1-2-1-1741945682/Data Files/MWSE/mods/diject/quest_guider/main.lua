--- @param e initializedEventData
local function initializedCallback(e)
    local config = include("diject.quest_guider.config")
    if config.data.main.enabled then
        include("diject.quest_guider.entry").initialize()
    end
end
event.register(tes3.event.initialized, initializedCallback, {priority = -278})

--- @param e modConfigReadyEventData
local function modConfigReadyCallback(e)
    include("diject.quest_guider.UI.mcm").registerModConfig()
end

event.register(tes3.event.modConfigReady, modConfigReadyCallback)