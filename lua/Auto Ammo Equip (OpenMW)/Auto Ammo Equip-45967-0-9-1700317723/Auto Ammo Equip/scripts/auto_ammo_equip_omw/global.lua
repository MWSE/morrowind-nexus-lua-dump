local I = require("openmw.interfaces")
local types = require("openmw.types")
local constants = require("scripts.auto_ammo_equip_omw.constants")


local ammoType = constants.ammoType

-- we use handler so equipping can be blocked by other mods
I.ItemUsage.addHandlerForType(types.Weapon, function(weapon, actor)
    local type = ammoType[types.Weapon.record(weapon).type]
    if type then
        actor:sendEvent("AAE_MarksmanWeaponEquipped_eqnx", {
            ammoType = type
        })
    end
end)
