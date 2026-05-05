return {
    eventHandlers = {
        SunsDusk_downgradeWorldConsumable = function(data)
            local actor = data[1]
            local obj = data[2]
            actor:sendEvent("WretchedAndWeird_SDInteraction", obj)
        end
    }
}