local self = require('openmw.self')
local core = require('openmw.core')

local initAlarm = nil

local function getAlarm()
    return self.type.stats.ai.alarm(self).base
end

local function setAlarm(alarm)
    if getAlarm() ~= alarm then
        self.type.stats.ai.alarm(self).base = alarm
    end
end

local function onInit(initData)
    initAlarm = getAlarm()
    core.sendGlobalEvent('setAlarmConditional', {npc = self, initAlarm = initAlarm})
end

local function onLoad(savedData, initData)
    initAlarm = savedData
    core.sendGlobalEvent('setAlarmConditional', {npc = self, initAlarm = initAlarm})
end

local function onSave()
    return initAlarm
end

return {
    eventHandlers = {
        setAlarm = setAlarm
    },
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave
    }
}
