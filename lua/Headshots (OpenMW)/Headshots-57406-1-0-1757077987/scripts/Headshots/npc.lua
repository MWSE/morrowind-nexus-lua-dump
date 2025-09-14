local I = require('openmw.interfaces')
require("scripts.Headshots.headshotLogic")

I.Combat.addOnHitHandler(function(attack)
    DoHeadshot(attack)
end)