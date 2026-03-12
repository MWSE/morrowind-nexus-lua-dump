local types = require("openmw.types")
local I     = require("openmw.interfaces")

local lastAttacker = nil
local lastWeapon   = nil

return {
    engineHandlers = {
        onActive = function()
            I.Combat.addOnHitHandler(function(attack)
                if not attack.successful then return end
                if not attack.attacker or not attack.attacker:isValid() then return end
                lastAttacker = attack.attacker
                lastWeapon   = attack.weapon
            end)
        end,
    },
    eventHandlers = {
        Died = function()
            if not lastAttacker or not lastAttacker:isValid() then return end
            if not types.Player.objectIsInstance(lastAttacker) then return end
            if not lastWeapon or not lastWeapon:isValid() then return end
            if not types.Weapon.objectIsInstance(lastWeapon) then return end
            local weaponType = types.Weapon.record(lastWeapon).type
            lastAttacker:sendEvent("AxeKill", { weaponType = weaponType })
        end,
    },
}