local self = require('openmw.self')
local types = require('openmw.types')
local AIStats = types.Actor.stats.ai
local storage = require('openmw.storage')
local settings = storage.globalSection('Settings_more_peaceful_tombs')

-- target base values for pacified creatures
-- hardcoded, taken from vanilla guards
local TARGET_HELLO = 30
local TARGET_FLEE = 0
local TARGET_FIGHT = 30
local TARGET_ALARM = 100

local save_hello
local save_flee
local save_fight
local save_alarm

local is_already_pacified = false

local function tomb_pacify(data)
    is_debug = settings:get('is_debug')

    if not is_already_pacified then
        if is_debug then
            print("pacifying " .. self.object.recordId .. " " .. self.object.id)
        end

        save_hello = AIStats.hello(self).base
        save_flee = AIStats.flee(self).base
        save_fight = AIStats.fight(self).base
        save_alarm = AIStats.alarm(self).base

        AIStats.hello(self).base = TARGET_HELLO
        AIStats.flee(self).base = TARGET_FLEE
        AIStats.fight(self).base = TARGET_FIGHT
        AIStats.alarm(self).base = TARGET_ALARM

        self:sendEvent('RemoveAIPackages', 'Combat')

        is_already_pacified = true
    end
end

local function tomb_unpacify()
    is_debug = settings:get('is_debug')

    if is_already_pacified then
        if is_debug then
            print("unpacifying " .. self.object.recordId .. " " .. self.object.id)
        end

        AIStats.hello(self).base = save_hello
        AIStats.flee(self).base = save_flee
        AIStats.fight(self).base = save_fight
        AIStats.alarm(self).base = save_alarm
        
        is_already_pacified = false
    end
end

local function onSave()
    return {
        is_already_pacified = is_already_pacified,
        save_hello = save_hello,
        save_flee = save_flee,
        save_fight = save_fight,
        save_alarm = save_alarm,
    }
end

local function onLoad(data)
    if data then
        is_already_pacified = data.is_already_pacified
        save_hello = data.save_hello
        save_flee = data.save_flee
        save_fight = data.save_fight
        save_alarm = data.save_alarm
    end
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onInactive = tomb_unpacify,
    },
    eventHandlers = {
        TombPacify = tomb_pacify,
    },
}