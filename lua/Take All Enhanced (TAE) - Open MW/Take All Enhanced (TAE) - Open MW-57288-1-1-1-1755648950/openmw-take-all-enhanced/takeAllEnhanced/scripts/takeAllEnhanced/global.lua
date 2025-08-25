local types = require("openmw.types")
local core = require("openmw.core")

return {
    eventHandlers = {
        addItemInPlayerInventory = function(data)
            data.item:moveInto(types.Actor.inventory(data.player))
            core.sound.playSound3d("shock bolt", data.player)
        end        
    },
}