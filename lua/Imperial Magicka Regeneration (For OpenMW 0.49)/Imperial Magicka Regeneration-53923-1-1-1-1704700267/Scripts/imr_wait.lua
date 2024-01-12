local NPC = require('openmw.types').NPC
local storage = require('openmw.storage')
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local UI = require('openmw.interfaces').UI


local settings = {
    main = storage.playerSection('NMRSettingsA'),
    additions = storage.playerSection('NMRSettingsB'),
    guilds = storage.playerSection('NMRSettingsGuildsPage'),
}

local initialized = false
local atronachMultiplier = 1
local regenStat = types.Actor.stats.attributes.intelligence(self).modified
local oneSecond = 1
local activeEffects = types.Actor.activeEffects(self)
local gameToRealTime = 0

local fortifyMagnitude = 0
local magickaCurrentFrame
local magickaLastFrame
local totalPotionMagicka = 0

local isResting = false

local fortifyMagickaEff = 0


local percentageTolerance = 1

                    -- Calculate the expected percentage change based on intelligence
local expectedPercentageChange = 0.15 * types.Actor.stats.attributes.intelligence(self).modified

                    -- Calculate the actual percentage change
local actualPercentageChange = 0
local percentageDifference = 0
local magickaDifference = 0

local regenAmount = 0

local artifactMultiplier = 0
local telvanniMultiplier = 0
local cultAbilityTime = 0
local cultAbilityMult = 0
local cultAbilityInSeconds = 0
local positiveBonusesWithAbility = 0
local regenAmountAbil = 0
local regenTimeAbil = 0

local isInRestMode = false

local function amIResting()
    return isInRestMode
end

local function potionsCheck()
    local restoreMagickaEff = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.RestoreMagicka)
    local fortifyMagickaEff = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.FortifyMagicka)

    totalPotionMagicka = 0
    if restoreMagickaEff then
        local potionEffects = {}

        -- Iterate through active spells
        for spellId, spellInfo in pairs(types.Actor.activeSpells(self)) do
            --print('Active Spell '..tostring(spellId)..':')
            
            -- Check if the spell has effects
            if spellInfo.effects then
                -- Iterate through effects and extract relevant information
                for _, effect in pairs(spellInfo.effects) do
                    if effect.id == "restoremagicka" then
                        --print('  Yes, there is an effect with ID "restoremagicka"')
                        
                        -- Check if the effect has magnitudeThisFrame and durationLeft
                        if effect.magnitudeThisFrame and effect.durationLeft then
                            -- Create a table with relevant information
                            local potionEffect = {
                                magnitude = effect.magnitudeThisFrame,
                                durationLeft = effect.durationLeft
                            }

                            -- Add the potion effect to the table
                            table.insert(potionEffects, potionEffect)
                        end
                    end
                end
            end
        end

        
        for _, effect in pairs(potionEffects) do
            if effect.durationLeft > 120 then
            totalPotionMagicka = totalPotionMagicka + (effect.magnitude * 120)
            --print('А магии за зелья и свитки мы за час восстановим вот столько: ' ..totalPotionMagicka)
            else
                --print('Осталось секунд: ' ..effect.durationLeft)
                if effect.durationLeft > 0 then
                    totalPotionMagicka = totalPotionMagicka + (effect.magnitude * effect.durationLeft)
                    --print('А магии за зелья и свитки мы за час восстановим вот столько: ' ..totalPotionMagicka)
                end
            end
        end
        

    end

    return totalPotionMagicka
end

local function magnitudeCheck()
    local fortifyMagickaEff = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.FortifyMagicka)
    if fortifyMagickaEff then
        fortifyMagnitude = fortifyMagickaEff.magnitude
    else
        fortifyMagnitude = 0
    end
    return fortifyMagnitude
end

local function restRegenReset()
    totalPotionMagicka = potionsCheck()
    atronachMultiplier = 1
    magickaLastFrame = magickaCurrentFrame
    timeLastFrame = timeCurrentFrame
end

local function checkForVanillaTolerance()
    percentageTolerance = 1

    -- Calculate the expected percentage change based on intelligence
    expectedPercentageChange = 0.15 * types.Actor.stats.attributes.intelligence(self).modified

    -- Calculate the actual percentage change
    actualPercentageChange = magickaDifference - totalPotionMagicka
    percentageDifference = math.abs((actualPercentageChange - expectedPercentageChange) / expectedPercentageChange) * 100
    --print('Различие в процентах: ' .. percentageDifference)
    -- Check if the actual percentage change is within the acceptable range
    if percentageDifference < percentageTolerance then
        -- Your logic for handling the acceptable change
        --print('Resting, are we?')
        --print('Vanilla regeneration is aborted: ' .. magickaCurrentFrame .. ' - ' .. expectedPercentageChange .. ' = ' .. magickaCurrentFrame - expectedPercentageChange .. ' Preparing for IMPERIAL regeneration')
        magickaCurrentFrame = magickaCurrentFrame - expectedPercentageChange
        types.Actor.stats.dynamic.magicka(self).current = magickaCurrentFrame
        isResting = true
        --print('Установилось? ' .. tostring(isResting))

        
    else
        -- Your logic for handling the unacceptable change
        --print('No rest for the wicked.')
        isResting = false
    end
end

local function getAtronachMult()
    if types.Actor.spells(self).wombburn then
        atronachMultiplier = settings.additions:get('NMRAtronachMultiplier')
    end
end

local function calculateRegenAmount()

end

local function regenerateMagicka(current, max, amount)
    if current <= max then
        local newValue = math.min(current + amount, max)
        types.Actor.stats.dynamic.magicka(self).current = newValue
        local regenType = isResting and "до максимума" or ""
        --print(string.format('За час отдыха мы восстановили вот столько, %s: %d +%d = %d', regenType, current, amount, newValue))
    end
end

local function onFrame(dt)
    if settings.additions:get('NMRrestHandler') then
    --print(I.UI.getMode())
        if I.UI.getMode() == 'Rest' then



            --If we have Atronach sign or modification is disabled, don't do nothing
            if settings.main:get('NMRisActive') == false or types.Actor.spells(self).wombburn and settings.additions:get('NMRAtronachSign') then
                --print("Modification is disabled or Atronach sign prevents regeneration")
                return
            end

            --Initialiae some variables for the first frame of UI Rest mode

            if not initialized then
                -- Assign initial values when entering 'Rest' mode
                --print('Инициализировано')
                magickaLastFrame = types.Actor.stats.dynamic.magicka(self).current
                --print('Первая магия прошлого фрейма: ' .. magickaLastFrame)
                timeLastFrame = core.getGameTime()
                totalPotionMagicka = potionsCheck()
                initialized = true
                return
            end

            timeCurrentFrame = core.getGameTime()
            --print('А потом проверяем, есть ли магия прошлого фрейма: ' .. magickaLastFrame)

            --Check for a certain effect on the player
            
            magickaCurrentFrame = types.Actor.stats.dynamic.magicka(self).current
            if timeLastFrame < timeCurrentFrame then
                
                timeDifference = timeCurrentFrame - timeLastFrame
                --print('Time difference since the last check: ' .. timeDifference)
                if timeDifference > 1 then
                    isInRestMode = true
                    local maxMagicka = types.Actor.stats.dynamic.magicka(self).base
                    local magickaMagnitude = magnitudeCheck()
                    --print('Total potion values ' .. totalPotionMagicka)
                    
                    magickaCurrentFrame = types.Actor.stats.dynamic.magicka(self).current

                    local isAtMaxMagicka = magickaLastFrame >= maxMagicka + magickaMagnitude
                    local willBeRestoredByPotions = magickaLastFrame + totalPotionMagicka >= maxMagicka + magickaMagnitude
                    if isAtMaxMagicka or willBeRestoredByPotions then
                        restRegenReset()
                        local reason = isAtMaxMagicka and "we already are at our maximum magicka" or "potions will restore our total magicka"
                        --print('No need for regeneration - ' .. reason)
                        return
                    end
                    --print('Well, thats what our LAST FRAME magicka looks like: ' ..magickaLastFrame.. ' And the CURRENT VALUE: ' ..magickaCurrentFrame )
                    
                    --magickaCurrentFrame = magickaLastFrame
                    
                    magickaDifference = magickaCurrentFrame - magickaLastFrame
                    local withoutPotions = magickaDifference - totalPotionMagicka
                    --print('А без зелий мы восстановили вот столько: ' .. withoutPotions)
                    --print('Вот на столько магия изменилась: ' .. magickaDifference)
                    -- Define a percentage tolerance (e.g., 1%)
                    
                    --Check if we are waiting or resting based on vanilla regeneration formula
                    checkForVanillaTolerance()

                    
                    
                    --Checking if there's an Atronach multiplier
                    getAtronachMult()
                    
                    --Checking if there's an active Fortify Magicka effect
                    fortifyMagnitude = magnitudeCheck()
                    
                    if settings.additions:get('NMRIntRegen') then
                        regenStat = types.Actor.stats.attributes.intelligence(self).modified 
                    else
                        regenStat = types.Actor.stats.attributes.willpower(self).modified
                    end

                    local currentMagicka = types.Actor.stats.dynamic.magicka(self).current
                    --print('Вот столько у нас сейчас магии: ' .. currentMagicka)
                    local maxRegenerableMagicka = I.IMRRegenUtil.calculateMaxRegenAmount(maxMagicka, fortifyMagnitude)
                    if not isResting and currentMagicka >= maxRegenerableMagicka then
                        restRegenReset()
                        --print('No need for regeneration - we are waiting and our magicka is equal to max possible percent')
                        return
                    end
                    --print('А вот до такого значения мы можем восстановить: ' .. maxRegenerableMagicka)
                    
                    if settings.additions:get('NMRArtMultiplier') then
                        artifactMultiplier = I.IMRART.getArtifactMultiplier()
                    end
                    if settings.guilds:get('NMRGuildsTelvanni') then
                        telvanniMultiplier = I.IMRGUILDS.telvanniGuildBonus()
                    end
                    if settings.guilds:get('NMRGuildsImperialCult') then
                        cultAbilityTime = I.IMR_ABIL_RESIL.resilienceTimeLeft()
                        cultAbilityMult = I.IMR_ABIL_RESIL.cultAbilityMultiplier()
                    end
                    if cultAbilityTime > 0 then
                        --print('Ух ты, абилка работает!')
                        cultAbilityInSeconds = cultAbilityTime / core.getGameTimeScale()
                        positiveBonusesWithAbility = 1 + telvanniMultiplier + artifactMultiplier + cultAbilityMult
                        --print('Вместе с бонусами получаем такой множитель: ' ..positiveBonusesWithAbility)
                        regenAmountAbil, regenTimeAbil = I.IMRRegenUtil.calculateRegenAmount(maxMagicka, regenStat, cultAbilityInSeconds, oneSecond)
                        regenAmountAbil = regenAmountAbil * positiveBonusesWithAbility
                        --print('С абилкой за ' ..cultAbilityInSeconds.. ' секунд мы восстановим вот столько: ' ..regenAmountAbil)
                        regenAmountAbil = regenAmountAbil * atronachMultiplier
                        if isResting then
                            regenerateMagicka(currentMagicka, maxMagicka + fortifyMagnitude, regenAmountAbil)
                        else
                            regenerateMagicka(currentMagicka, maxRegenerableMagicka, regenAmountAbil)
                        end
                    end
                    
                    if cultAbilityTime > 0 then
                        gameToRealTime = (timeDifference - cultAbilityTime) / core.getGameTimeScale()
                        cultAbilityTime = 0
                    else
                        gameToRealTime = timeDifference / core.getGameTimeScale()
                    end
                    local regenAmount, regenTime = I.IMRRegenUtil.calculateRegenAmount(maxMagicka, regenStat, gameToRealTime, oneSecond)
                    --print('А восстанавливать мы в час будем вот столько: ' .. regenAmount)
                    local positiveBonuses = 1 + telvanniMultiplier + artifactMultiplier
                    regenAmount = regenAmount * positiveBonuses
                    --print('После учёта позитивных бонусов - вот столько: ' .. regenAmount)
                    regenAmount = regenAmount * atronachMultiplier
                    --print('Если у нас есть знак Атронаха, восстановим вот столько, иначе умножим на 1: ' .. regenAmount)
                    --print('Всё ущё установлено? ' .. tostring(isResting))

                    --Calculating the regen amount based on waiting or resting check
                    if isResting then
                        regenerateMagicka(currentMagicka, maxMagicka + fortifyMagnitude, regenAmount)
                    else
                        regenerateMagicka(currentMagicka, maxRegenerableMagicka, regenAmount)
                    end

                    totalPotionMagicka = potionsCheck()
                    atronachMultiplier = 1
                    magickaLastFrame = types.Actor.stats.dynamic.magicka(self).current
                end
            end

            timeLastFrame = timeCurrentFrame
            
            
        else
            initialized = false
            isInRestMode = false
        end
    end
    
end



return {
    engineHandlers = {
        dt = dt,
        onFrame = onFrame,
    },
    interfaceName = "IMR_WAIT",
    interface = {
        amIResting = amIResting, 
    },
}