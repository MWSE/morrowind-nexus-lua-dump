local world = require('openmw.world') --- We can use functions that affect the entire world, like global variables or the actual positions of objects

return {
    eventHandlers = {
        playerAttacked = function(player)
        --- print("One Attack!") --- This is just so you know it's happening, no need for it
        world.mwscript.getGlobalVariables(player).fs_WeaponSwish = 1
        end
    }
}