local self = require("openmw.self")

local function setMaxAlarm()
    if self.type.stats.ai.alarm(self).base ~= 100 then
        self.type.stats.ai.alarm(self).base = 100
    end
end

return {
    eventHandlers = {
        setMaxAlarm = setMaxAlarm
    }
}
