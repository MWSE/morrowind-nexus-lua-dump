local function onActorActive(actor)
    actor:sendEvent('setMaxAlarm')
end

return {
    engineHandlers = {
        onActorActive = onActorActive
    }
}
