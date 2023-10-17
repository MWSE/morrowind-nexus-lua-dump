local config = require('MechanicsRemastered.config')

-- Magicka Regen

local function magickaPerSecond(int)
    local mult = tes3.findGMST(tes3.gmst.fRestMagicMult).value
    local rps = (mult * int) / 60 / 60
    return rps
end

local function magickaRegenCalculation(int)
    local rps = magickaPerSecond(int)
    local ts = tes3.findGlobal("timescale").value
    return rps * ts
end

local function regenMagicka()
    if (config.MagickaRegenEnabled == true) then
        -- Check for the atronach birthsign.
        local atronach = tes3.isAffectedBy({ reference = tes3.mobilePlayer, effect = tes3.effect.stuntedMagicka })

        -- If magicka isn't full and the player does not have the atronach sign, run regen.
        if (atronach == false and tes3.mobilePlayer.magicka.current < tes3.mobilePlayer.magicka.base) then
            local int = tes3.mobilePlayer.intelligence.current
            local regen = magickaRegenCalculation(int)

            local newMagicka = tes3.mobilePlayer.magicka.current + regen
            if (newMagicka > tes3.mobilePlayer.magicka.base) then
                newMagicka = tes3.mobilePlayer.magicka.base
            end

            tes3.setStatistic{ reference = tes3.player, name = "magicka", current = newMagicka }
        end

        -- Repeat the calculation for any NPCs and creatures.
        for _, cell in pairs(tes3.getActiveCells()) do
            for ref in cell:iterateReferences{tes3.objectType.npc, tes3.objectType.creature} do
                if (ref.mobile) then 
                    if (ref.mobile.magicka.current < ref.mobile.magicka.base) then
                        local npcatronach = tes3.isAffectedBy({ reference = ref, effect = tes3.effect.stuntedMagicka })
                        if (npcatronach == false) then
                            local npcint = ref.mobile.intelligence.current
                            local npcregen = magickaRegenCalculation(npcint)
                
                            local newNpcMagicka = ref.mobile.magicka.current + npcregen
                            if (newNpcMagicka > ref.mobile.magicka.base) then
                                newNpcMagicka = ref.mobile.magicka.base
                            end
                
                            tes3.setStatistic{ reference = ref.mobile, name = "magicka", current = newNpcMagicka }
                        end
                    end
                end
            end
        end
    end
end

--- @param e calcRestInterruptEventData
local function calcRestInterruptCallback(e)
    if (config.MagickaRegenEnabled == true and e.waiting == true) then
        local atronach = tes3.isAffectedBy({ reference = tes3.mobilePlayer, effect = tes3.effect.stuntedMagicka })
        if (atronach == false) then
            local totalRestHours = tes3.mobilePlayer.restHoursRemaining
            local interruptHours = e.hour
            if (interruptHours < 0) then
                interruptHours = 0
            end
            local totalRest = totalRestHours - interruptHours
            local int = tes3.mobilePlayer.intelligence.current
            local totalRegen = magickaPerSecond(int) * 60 * 60 * totalRest
            local newMagicka = tes3.mobilePlayer.magicka.current + totalRegen
            if (newMagicka > tes3.mobilePlayer.magicka.base) then
                newMagicka = tes3.mobilePlayer.magicka.base
            end
            tes3.setStatistic{ reference = tes3.player, name = "magicka", current = newMagicka }
        end
    end
end

--- @param e loadedEventData
local function loadedCallback(e)
    timer.start{iterations = -1, duration = 1, callback = regenMagicka}
end

event.register(tes3.event.calcRestInterrupt, calcRestInterruptCallback)
event.register(tes3.event.loaded, loadedCallback)
mwse.log(config.Name .. ' Magicka Regen Module Initialised.')