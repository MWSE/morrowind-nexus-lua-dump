local I = require('openmw.interfaces')
local self = require('openmw.self')
if self.recordId ~= "tbd_necromancer" then
    return {

    }
end
I.Combat.addOnHitHandler(function(attack)
    -- Only act if the hit deals health damage
if self.type.stats.skills.acrobatics(self).modified > 1 then
    if attack.damage.health and attack.damage.health > 0  then
        local hit = attack.damage.health
        local current = self.type.stats.dynamic.health(self).current

        -- If this hit would drop HP below 20, clamp it
        if (current - hit) < 20 then
            -- Reduce the health damage to only take them to 20 HP
            self.type.stats.dynamic.health(self).current = 20
            attack.damage.health = 1
            if attack.damage.health < 0 then
                -- Prevent negative damage (healing)
                attack.damage.health = 1
            end
        end
        print(current - hit)
        print(current, hit)
    end
end
end)