local I = require('openmw.interfaces')
require("scripts.ModernMehrunesRazor.instakillLogic")

I.Combat.addOnHitHandler(function(attack)
    DoInstakill(attack)
end)