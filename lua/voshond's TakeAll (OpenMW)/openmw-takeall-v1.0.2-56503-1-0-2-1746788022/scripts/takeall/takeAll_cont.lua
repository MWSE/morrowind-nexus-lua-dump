local core = require('openmw.core')
local self = require('openmw.self')
local Debug = require("scripts.TakeAll.takeAll_debug")

-- Container animation handling
local animatingContainers = {}

-- Open container animation
local function openAnimation(data)
    Debug.log("TakeAll", "Opening container animation")

    -- Get the activator (player)
    local player = data and data[1]

    if not player then
        Debug.log("TakeAll", "Warning: No player provided to openAnimation")
        return
    end

    -- Don't interrupt default container behavior
    -- We only want to play animations when the TakeAll key is pressed

    -- Track this container as being animated
    animatingContainers[player.id] = true

    -- Start open animation if container supports it
    if self.animations and self.animations:hasScript("ContainerOpen") then
        Debug.log("TakeAll", "Playing container open animation")
        self.animations:playScript("ContainerOpen")
    end
end

-- Close container animation
local function closeAnimation(data)
    Debug.log("TakeAll", "Closing container animation")

    -- Get the activator (player)
    local player = data and data[1]

    if not player then
        Debug.log("TakeAll", "Warning: No player provided to closeAnimation")
        return
    end

    -- Remove this player from animating containers
    animatingContainers[player.id] = nil

    -- Play close animation if container supports it
    if self.animations and self.animations:hasScript("ContainerClose") then
        Debug.log("TakeAll", "Playing container close animation")
        self.animations:playScript("ContainerClose")
    end
end

-- Return the script interface
return {
    eventHandlers = {
        TakeAll_openAnimation = openAnimation,
        TakeAll_closeAnimation = closeAnimation
    }
}
