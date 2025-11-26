local I = require('openmw.interfaces')
require("scripts.Backstabs.backstabLogic")

I.Combat.addOnHitHandler(function(attack)
    DoBackstab(attack)
end)

return {
    eventHandlers = {
        playerSneaking = UpdatePlayerSneakStatus,
        playerInvisible = UpdatePlayerInvisStatus,
    }
}