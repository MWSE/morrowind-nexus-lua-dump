local world = require("openmw.world")

local script = "scripts/Frana5usBackgrounds/backgrounds_custom/denyingGreen.lua"
local registeredPlayers = {}

local function onActorActive(actor)
    if not next(registeredPlayers) then return end
    if actor.recordId ~= "guar"
        and actor.recordId ~= "scrib"
        and not actor.recordId:find("^guar_")
        and not actor.recordId:find("^guar ")
        and not actor.recordId:find("^scrib_")
        and not actor.recordId:find("^scrib ")
    then
        return
    end
    actor:addScript(script, registeredPlayers)
end

for _, actor in ipairs(world.activeActors) do
    onActorActive(actor)
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
    },
    eventHandlers = {
        Frana5usBackgrounds_registerDenyingGreen = function(player)
            registeredPlayers[#registeredPlayers + 1] = player
        end,
    },
}
