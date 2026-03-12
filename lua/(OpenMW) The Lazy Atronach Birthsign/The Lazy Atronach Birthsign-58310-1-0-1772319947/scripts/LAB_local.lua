local AI = require('openmw.interfaces').AI

return {
    eventHandlers = {
        ForceGhostAttack = function(data)
            local target = data.target
            if not target or not target:isValid() then return end

            AI.startPackage({
                type = 'Combat',
                target = target,
                cancelOther = true 
            })
        end
    }
}