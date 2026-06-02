-- Declarations --
local AI = require("openmw.interfaces").AI
local nearby = require("openmw.nearby")

-- start follower AI
local function loadFriendlyCritterBehavior()
    AI.startPackage({
        type='Follow',
        cancelOther = true,
        target = nearby.players[1],
        duration = 60,
        isRepeat = true
    })
end

return {
    eventHandlers = {
        loadFriendlyCritterBehavior = loadFriendlyCritterBehavior
    }
}
