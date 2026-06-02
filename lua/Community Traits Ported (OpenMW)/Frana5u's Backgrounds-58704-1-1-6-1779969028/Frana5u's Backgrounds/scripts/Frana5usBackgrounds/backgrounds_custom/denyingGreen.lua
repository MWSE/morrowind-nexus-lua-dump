local time = require("openmw_aux.time")
local self = require("openmw.self")

local period = 1
local stopTimer

local function onInit(players)
    stopTimer = time.runRepeatedly(
        function()
            for _, player in ipairs(players) do
                if (self.position - player.position):length() < 600 then
                    self.type.stats.ai.fight(self).base = 100
                    stopTimer()
                end
            end
        end,
        period
    )
end

return {
    engineHandlers = {
        onInit = onInit,
    },
    eventHandlers = {
        Died = function()
            if stopTimer then
                stopTimer()
            end
        end,
    },
}
