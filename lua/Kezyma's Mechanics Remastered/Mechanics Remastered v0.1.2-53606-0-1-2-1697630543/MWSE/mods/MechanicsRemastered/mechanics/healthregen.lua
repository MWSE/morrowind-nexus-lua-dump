local config = require('MechanicsRemastered.config')
local K = require('MechanicsRemastered.mechanics.common')

-- Health Regen

local function regenHealth()
    if (config.HealthRegenEnabled == true) then
        if (tes3.mobilePlayer.inCombat == false) then 
            local maxHealth = tes3.mobilePlayer.health.base
            -- If health isn't full, run regen.
            if (tes3.mobilePlayer.health.current < maxHealth) then
                local endurance = tes3.mobilePlayer.endurance.current
                local regen = K.healthRegenCalculation(endurance)
    
                local newHealth = tes3.mobilePlayer.health.current + regen
                if (newHealth > maxHealth) then
                    newHealth = maxHealth
                end
    
                tes3.setStatistic{ reference = tes3.player, name = "health", current = newHealth }
            end
        end

        -- Repeat the calculation for any NPCs and creatures.
        for _, cell in pairs(tes3.getActiveCells()) do
            for ref in cell:iterateReferences{tes3.objectType.npc, tes3.objectType.creature} do
                if (ref.mobile) then 
                    if (ref.mobile.inCombat == false) then
                        local npcMaxHealth = ref.mobile.health.base
                        if (ref.mobile.health.current < npcMaxHealth) then
                            local npcend = ref.mobile.endurance.current
                            local npcregen = K.healthRegenCalculation(npcend)
                
                            local newNpcHealth = ref.mobile.health.current + npcregen
                            if (newNpcHealth > npcMaxHealth) then
                                newNpcHealth = npcMaxHealth
                            end
                
                            tes3.setStatistic{ reference = ref.mobile, name = "health", current = newNpcHealth }
                        end
                    end
                end
            end
        end
    end
end

--- @param e loadedEventData
local function loadedCallback(e)
    timer.start{iterations = -1, duration = 1, callback = regenHealth}
end

--- @param e calcRestInterruptEventData
local function calcRestInterruptCallback(e)
    if (config.HealthRegenEnabled == true and e.waiting == true) then
        local totalRestHours = tes3.mobilePlayer.restHoursRemaining
        local interruptHours = e.hour
        if (interruptHours < 0) then
            interruptHours = 0
        end
        local totalRest = totalRestHours - interruptHours
        local int = tes3.mobilePlayer.endurance.current
        local totalRegen = K.healthPerSecond(int) * 60 * 60 * totalRest
        local newHealth = tes3.mobilePlayer.health.current + totalRegen
        if (newHealth > tes3.mobilePlayer.health.base) then
            newHealth = tes3.mobilePlayer.health.base
        end
        tes3.setStatistic{ reference = tes3.player, name = "health", current = newHealth }
    end
end

event.register(tes3.event.calcRestInterrupt, calcRestInterruptCallback)
event.register(tes3.event.loaded, loadedCallback)
mwse.log(config.Name .. ' Health Regen Module Initialised.')