local I = require('openmw.interfaces')
require("scripts.UmbraUnlimited.soultrapLogic")

I.Combat.addOnHitHandler(function(attack)
    DoSoultrap(attack)
end)