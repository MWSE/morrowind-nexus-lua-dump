local mp = "scripts/MaxYari/ReAnimation_v2/"

local I = require('openmw.interfaces')
local animation = require('openmw.animation')
local omwself = require('openmw.self')

local EventsManager = require(mp .. "scripts/events_manager")

local events = EventsManager:new()

local function addOnKeyHandler(cb)
    events:addEventHandler(cb)
end

local function removeOnKeyHandler(cb)
    events:removeEventHandler(cb)
end

local Animation = {}

function Animation:play(groupname, opts)
    local anim = {
        groupname = groupname,
        opts = opts
    }

    I.AnimationController.playBlendedAnimation(anim.groupname, anim.opts)

    setmetatable(anim, self)
    self.__index = self

    return anim
end

function Animation:cancel()
    animation.cancel(omwself, self.groupname)
end

local function isPlaying(groupname)
    local time = animation.getCurrentTime(omwself, groupname)
    return time and time >= 0
end

function Animation:isPlaying()
    return isPlaying(self.groupname)
end

function Animation:addOnKeyHandler(cb)
    self.eventHandler = function(groupname, key)
        if groupname == self.groupname then
            cb(groupname, key)
        end
    end
    addOnKeyHandler(self.eventHandler)
end

function Animation:removeOnKeyHandler()
    if not self.eventHandler then return end
    removeOnKeyHandler(self.eventHandler)
end

I.AnimationController.addTextKeyHandler(nil, function(...)
    events:emit(...)
end)

local module = {
    Animation = Animation,
    isPlaying = isPlaying,
    addOnKeyHandler = addOnKeyHandler,
    removeOnKeyHandler = removeOnKeyHandler
}

return module
