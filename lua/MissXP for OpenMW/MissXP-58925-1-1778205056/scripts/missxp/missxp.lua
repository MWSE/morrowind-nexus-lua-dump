---@diagnostic disable: undefined-field
local I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')


I.Combat.addOnHitHandler(function(attack)
    if not attack.successful
    and types.Player.objectIsInstance(attack.attacker)
    then
        --print('handler OK!')
        local weaponType = nil

        if attack.ammo and types.Weapon.records[attack.ammo] then
            weaponType = types.Weapon.records[attack.ammo].type
        elseif attack.weapon then
            weaponType = types.Weapon.records[attack.weapon.recordId].type
        else
            weaponType = "unarmed"
        end

       
       attack.attacker:sendEvent('OnMiss', { weaponType = weaponType })

    end
end)