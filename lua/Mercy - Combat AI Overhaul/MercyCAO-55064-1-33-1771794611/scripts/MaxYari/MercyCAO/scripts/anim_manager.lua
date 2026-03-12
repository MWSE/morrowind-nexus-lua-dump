local mp = "scripts/MaxYari/MercyCAO/"

local I = require('openmw.interfaces')
local animation = require('openmw.animation')
local omwself = require('openmw.self')

local EventsManager = require(mp .. "scripts/events_manager")

local events = EventsManager:new()

local animationConfigs = {
    stand_ground_idle = {
        groupname = { "stayaway1", "stayaway3", "stayaway4" },
        priority = animation.PRIORITY.Hit,
        blendmask = animation.BLEND_MASK.LowerBody
    },
    surrender_mercy = {
        groupname = "surrender",
        startkey = "start",
        stopkey = "offer start",
        priority = animation.PRIORITY.Death - 1,
        blendmask = animation.BLEND_MASK.UpperBody
    },
    surrender_offer = {
        groupname = "surrender",
        startkey = "offer start",
        stopkey = "stop",
        priority = animation.PRIORITY.Death - 1,
    },
    surrender_postoffer = {
        groupname = "surrender",
        startkey = "place items",
        stopkey = "stop",
        priority = animation.PRIORITY.Hit
    }
}

-- Patching for animation API update:
for anim, opts in pairs(animationConfigs) do
    opts.startKey = opts.startkey
    opts.stopKey = opts.stopkey
    opts.blendMask = opts.blendmask
end



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
    removeOnKeyHandler = removeOnKeyHandler,
    animationConfigs = animationConfigs
}

return module
