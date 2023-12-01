require("scripts.roaming_creeper.openmw")
local AI = I.AI




local function hasFollowAi()
    local isFollowing = false
    AI.forEachPackage(function(package)
        if package.type == "Follow" or package.type == "Escort" then
            isFollowing = true
            return
        end
    end)
    return isFollowing
end






return {
    engineHandlers = {
        onUpdate = function()
            core.sendGlobalEvent("RoamingCreeper_update_eqnx", { hasFollowAi = hasFollowAi() })
        end
    },
    eventHandlers = {
        -- from global.lua
        RoamingCreeper_update_eqnx = function(data)
            if not data then return end
            local currentFatigue = types.Actor.stats.dynamic.fatigue(self).current
            types.Actor.stats.dynamic.fatigue(self).current = data.fatigue or currentFatigue -- creeper animation hack
        end
    }
}
