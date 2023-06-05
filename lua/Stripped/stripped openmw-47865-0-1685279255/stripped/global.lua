return {
    engineHandlers = {
        onActorActive = function(actor)
            actor:addScript("stripped/local.lua")
        end
    },
}
