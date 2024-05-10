--- @param e loadedEventData
local function loadedCallback(e)
    tes3.worldController.maxFPS = 25
end
event.register(tes3.event.loaded, loadedCallback)