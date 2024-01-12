--[[

Mod: Imperial Magicka Regeneration
Author: Craftymonkey (Always Hungry)

--]]

local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local NPC = require('openmw.types').NPC
local async = require('openmw.async')
local RegenUtil= require('scripts.imr_regen_util')


--Settings
local settings = {
    main = storage.playerSection('NMRSettingsA'),
    additions = storage.playerSection('NMRSettingsB'),
    guilds = storage.playerSection('NMRSettingsGuildsPage'),
}


local second = 1
local oneSecond = 1
local accumulatedTime = 0
local accumulatedRegen = 0

--Linking regeneration to the game time
local gameTimeLastFrame = core.getGameTime()

--Updating max and min regen values
local mxRegenTime
local mnRegenTime
local mxRegenTimeLastCheck
local mnRegenTimeLastCheck

--Fatigue penalties
local fatiguePenalties = {
    { threshold = 20, multiplier = 0.5},
    { threshold = 40, multiplier = 0.7},
    { threshold = 60, multiplier = 0.8},
    { threshold = 80, multiplier = 0.9},
}

--multipliers and stats
local baseSpeedMultiplier = 1
local totalModifier = 1
local regenStat = types.Actor.stats.attributes.intelligence(self).modified

--tick time
local tick_time = 0.1
local tick_timer = 0

--Variables for rest and wait
local magickaLastFrame = 0
local magickaCurrentFrame = 0
local initializeTime = 0

local restTimer = 0
local restTime = 5

local timeLastFrame = 0
local timeCurrentFrame = 0
local timeDifference = 0

local maxRegenPercentage = settings.main:get('NMRMaxRegenPercentage') / 100

local regenAmount
local positiveBonuses

--Fortify Magicka
local fortifyMagnitude = 0

local isResting = false
local onFrameTime = 5
local onFrameTimer = 0


-- Calculating regenerated magicka per second:
local function printMagickaRegenPerSecond(regenAmount, totalModifier)
    local regenPerSecond = regenAmount / second
    local formattedRegenPerSecond = string.format("%.2f", regenPerSecond)
    --print('Magicka Regeneration per Second: ' .. formattedRegenPerSecond)

    if totalModifier then
        --print('Total Modifier: ' .. totalModifier)
    end
end

local function getRegenAmount()
    return regenAmount
end

local function getTotalModifier()
    return totalModifier
end


local function onUpdate(dt)
    --print('onUpdate тут работает, или нет?')
    -- If the mod is not active or the player has Atronach sign and the settings don't allow regeneration with it, then the rest of the code shouldn't work
    if settings.main:get('NMRisActive') == false or types.Actor.spells(self).wombburn and settings.additions:get('NMRAtronachSign') then
        --print("Modification is disabled or Atronach sign prevents regeneration")
        return
    end

    tick_timer = tick_timer + dt

    if tick_timer >= tick_time then
        local atronachMultiplier = 1

        --print('Magnitude? ' .. fortifyMagicka.magnitude .. 'Duration?' .. fortifyMagicka.magnitudeModifier)

        if types.Actor.spells(self).wombburn then
            atronachMultiplier = settings.additions:get('NMRAtronachMultiplier')
            --print('Atronach multiplier: ' .. atronachMultiplier)
        end



        local currentMagicka = types.Actor.stats.dynamic.magicka(self).current
        local maxMagicka = types.Actor.stats.dynamic.magicka(self).base
        local isIntelligence = settings.additions:get('NMRIntRegen')
        local currentHealth = types.Actor.stats.dynamic.health(self).current


        if settings.additions:get('NMRFortifyMagicka') then
        local fortifyMagickaEff = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.FortifyMagicka)
            if fortifyMagickaEff then
                fortifyMagnitude = fortifyMagickaEff.magnitude
            else
                fortifyMagnitude = 0
            end
        end


        local maxRegenerableMagicka = I.IMRRegenUtil.calculateMaxRegenAmount(maxMagicka, fortifyMagnitude)
        --print('Calculation complete. Restoring to: ' .. maxRegenerableMagicka)
        --Calculating regen time
        local gameTimeCurrentFrame = core.getGameTime()
        local gameTimeDifference = (gameTimeCurrentFrame - gameTimeLastFrame) / core.getGameTimeScale()
        --print('Time per tick: ' ..gameTimeDifference)

        if gameTimeDifference >= 1 and isResting then
            --print('Regeneration calcelled based on time passed')
            gameTimeLastFrame = gameTimeCurrentFrame
            tick_timer = 0
            return
        end
        isResting = false

        

        
        if settings.additions:get('NMRIntRegen') then
            regenStat = types.Actor.stats.attributes.intelligence(self).modified 
        else
            regenStat = types.Actor.stats.attributes.willpower(self).modified
        end

        --Second check to ensure that we need to regenerate magicka at all
        if regenStat <= 0 
            or currentMagicka >= maxRegenerableMagicka 
            or currentHealth <= 0 then
            tick_timer = 0
            gameTimeLastFrame = gameTimeCurrentFrame
            --print('А магия не регенерирует, лоль')
            return
        end

        --resetting our modifiers to their initial values
        local fatigueMultiplier = 1
        totalModifier = 1
        
        

        local regenAmount, regenTime = I.IMRRegenUtil.calculateRegenAmount(maxMagicka, regenStat, gameTimeDifference, oneSecond)
        --print('Regen amount: ' .. regenAmount .. ' Regen time: ' .. regenTime)
        

        -- Calculating fatigue modifier
        if settings.additions:get('NMRFatigueMult') then
            local fatiguePercent = (types.Actor.stats.dynamic.fatigue(self).current / types.Actor.stats.dynamic.fatigue(self).base) * 100

            for _, penalty in ipairs(fatiguePenalties) do
                if fatiguePercent < penalty.threshold then
                    fatigueMultiplier = penalty.multiplier
                    --print('Эгегей! ' ..fatigueMultiplier)
                    break
                end
            end
        
            if settings.guilds:get('NMRGuildsTemple') then
                fatigueMultiplier = math.min(fatigueMultiplier + I.IMRGUILDS.templeGuildBonus(), 1)
                --print('Temple fatigue modifier: ' .. I.IMRGUILDS.templeGuildBonus())
                --print('Fatigue modifier with temple: ' .. fatigueMultiplier)
            end

            fatigueMultiplier = math.min(fatigueMultiplier + I.IMRART.getArtifactBonuses().fatigue, 1)
            --print('Fatigue modifier with arts: ' .. fatigueMultiplier)
        end
        
        local artifactMultiplier = I.IMRART.getArtifactBonuses().multiplier
        --print('Artifact modifier: ' .. artifactMultiplier)
        local telvanniMultiplier = I.IMRGUILDS.telvanniGuildBonus()
        --print('Telvanni modifier: ' .. telvanniMultiplier)
        local divineResilienceMult = I.IMR_ABIL_RESIL.cultAbilityMultiplier()
        --print('Бонус абилки: ' ..divineResilienceMult)
        -- calculating total amount based on what modifiers are turned on
        

        
        positiveBonuses = totalModifier + artifactMultiplier + telvanniMultiplier + divineResilienceMult
         
        local artifactThreshold = I.IMRART.getArtifactBonuses().lowMultThresh
        if I.IMRART.getArtifactBonuses().lowMultThresh ~= 0 then
            if currentMagicka < maxMagicka * artifactThreshold then
                local lowMagickaArtMult = I.IMRART.getArtifactBonuses().lowMultiplier
                --print('Получили бонусы для низкой магии: ' ..lowMagickaArtMult)
                positiveBonuses = positiveBonuses + lowMagickaArtMult
            end
        end
        totalModifier = positiveBonuses * fatigueMultiplier * atronachMultiplier
        --print(totalModifier)
        regenAmount = regenAmount * totalModifier
        --print('А восстанавливать мы будем вот столько:' .. regenAmount)

        --Calculating amount of regenerated magicka per second to show its value
        accumulatedTime = accumulatedTime + gameTimeDifference
        accumulatedRegen = accumulatedRegen + regenAmount

        -- Accumulate until one second has passed
        if accumulatedTime >= second then
            -- Print magicka regeneration per second
            --print('Восстановлено в секунду: ' .. accumulatedRegen .. '. Модификатор восстановления: ' .. totalModifier)
            --printMagickaRegenPerSecond(accumulatedRegen, totalModifier)
            --print('Время до полного восстановления (формула): ' .. regenTime)
            --print('Время до полного восстановления (магия / магия в секунду): ' .. maxMagicka / accumulatedRegen)
            --print('Регенерируем до: ' .. maxRegenerableMagicka .. ' Это ' .. (maxRegenerableMagicka / maxMagicka ) * 100 .. '% от общей магии.')
            --print('Позитивные бонусы (аддитивно): ' .. positiveBonuses)
            --print('Бонусы гильдий: Гильдия магов' .. I.IMRGUILDS.magesGuildBonus() .. ' Тельванни: ' .. I.IMRGUILDS.telvanniGuildBonus() .. ' Культ: ' .. I.IMRGUILDS.ImperialCultGuildBonus() .. ' Храм: ' .. I.IMRGUILDS.templeGuildBonus())
            --print('Бонус от абилки: ' .. I.IMR_ABIL_RESIL.cultAbilityMultiplier())
            --print('Модификатор при низкой магии: ' ..I.IMRART.getArtifactBonuses().lowMultiplier)
            --print('Модификатор силы абилки: ' ..I.IMRART.getArtifactBonuses().abilPower)
            --print('Трешолд за артефакты: ' ..I.IMRART.getArtifactBonuses().lowMultThresh)
            --print('Бонусы для стамины: ' ..I.IMRART.getArtifactBonuses().fatigue)
            --print('Бонусы для скорости регена от артов: ' ..I.IMRART.getArtifactBonuses().multiplier)
            --print('Бонусы времени абилки: ' ..I.IMRART.getArtifactBonuses().abilTime)

            -- Reset accumulated time and regeneration for the next second
            accumulatedTime = 0
            accumulatedRegen = 0
        end

        if currentMagicka < maxRegenerableMagicka then
            --print('Магии не хватает, регенерировать!')
            local newValue = math.min(currentMagicka + regenAmount, maxRegenerableMagicka)
            --print('Восстановили магию вот на столько: ' ..regenAmount)
            --print('До максимума во сколько? ' ..maxRegenerableMagicka)
            --print(newValue)
            types.Actor.stats.dynamic.magicka(self).current = newValue
            --print('Новое значение магии: ' .. newValue)
        end
        gameTimeLastFrame = gameTimeCurrentFrame
        tick_timer = 0
    end
end
--[[
local function onKeyPress(key)
    --if key.symbol == 'x' then
            --ambient.playSoundFile("Sound\\spell_sound.mp3", soundParams2)
    --end
end
--]]

local function onFrame(dt)
    onFrameTimer = onFrameTimer + 1
    if onFrameTimer >= onFrameTime then
        if I.UI.getMode() == 'Rest' then
            isResting = true
        end
        onFrameTimer = 0
    end
end

return {
    engineHandlers = {
        dt = dt,
        onUpdate = onUpdate,
        onKeyPress = onKeyPress,
        onFrame = onFrame,
    },
    interfaceName = "IMRREGEN",
    interface = {
        regenAmount = getRegenAmount,
        totalModifier = getTotalModifier,
        maxRegenerableMagicka = getMaxRegenerableMagicka,
        getRegenAmount = getRegenAmount,
    },
}
