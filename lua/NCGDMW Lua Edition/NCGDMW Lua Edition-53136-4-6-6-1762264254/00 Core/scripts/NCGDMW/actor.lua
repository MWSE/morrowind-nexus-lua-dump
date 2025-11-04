local T = require('openmw.types')
local I = require('openmw.interfaces')
local self = require('openmw.self')

local mDef = require('scripts.NCGDMW.definition')
local mCore = require('scripts.NCGDMW.core')

if not mDef.isOpenMW50 then return end

I.AnimationController.addTextKeyHandler('', function(group, key)
    if mCore.meleeAttackGroups[group] and mCore.meleeWeaponEndKeys[key] then
        local target = I.AI.getActiveTarget("Combat")
        if target and target.type == T.Player then
            target:sendEvent(mDef.events.onActorAnimHit, { actor = self, animGroup = group, animKey = key })
        end
    end
end)

I.Combat.addOnHitHandler(function(attack)
    if attack.successful and (attack.sourceType == "melee" or attack.sourceType == "ranged") then
        if attack.attacker.type == T.Player then
            attack.attacker:sendEvent(mDef.events.onActorHit, self)
        end
    end
end)
