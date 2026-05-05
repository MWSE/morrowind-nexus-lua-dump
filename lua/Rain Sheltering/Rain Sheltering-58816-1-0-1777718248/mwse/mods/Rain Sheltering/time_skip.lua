local state = require("Rain Sheltering.state")
local getCurrentTime = require("Rain Sheltering.getCurrentTime")

local function onRestWaitMenu(e)
    -- Меню "Отдых/Ожидание" открылось.
    state.waitState = {
        startHours = getCurrentTime()
    }
    -- Когда меню закроется (после завершения ожидания/сна), считаем прошедшее время.
    e.element:registerAfter(tes3.uiEvent.destroy, function()
        if not state.waitState then return end

        local elapsed = getCurrentTime() - state.waitState.startHours
        state.waitState = nil
        event.trigger("RainShelter:TimeSkip", { elapsedTime = elapsed })
    end)
end
event.register(tes3.event.uiActivated, onRestWaitMenu, { filter = "MenuTimePass" })