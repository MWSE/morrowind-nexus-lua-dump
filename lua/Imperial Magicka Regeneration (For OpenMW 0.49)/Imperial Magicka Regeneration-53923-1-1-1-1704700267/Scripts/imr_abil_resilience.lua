local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local core = require('openmw.core')
local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local NPC = require('openmw.types').NPC

-- Getting mod settings
local settings = {
    main = storage.playerSection('NMRSettingsA'),
    additions = storage.playerSection('NMRSettingsB'),
    guilds = storage.playerSection('NMRSettingsGuildsPage'),
}

--Variables
local imperialCultAbilityTimer = 0
local isImperialCultAbilityUsed = false
local isImperialCultAbilityCooldown = false
local imperialCultAbilityCooldownTime = 300
local divineResilienceCooldownTimer = 0
local divineResilienceMult = 5
local divineResilienceAbilityTimer = 0
local healthLastFrame = types.Actor.stats.dynamic.health(self).current
local cultAbilityMultiplier = 0
local healthWasDamaged

local gameTimeLastFrame = core.getGameTime()
local gameTimeCurrentFrame = 0
local gameTimeDifference = 0
local gameTimeCounter = 0

local isAbilityWorking = false
local resilienceAbilityTime = 10
local resilienceCooldownTime = 300
local resilienceTimeLeft = 0

local tick_time = 0.1
local tick_counter = 0

-- Sound parameters
local soundParams = {
    timeOffset=0,
    volume=2,
    scale=false,
    pitch=0.3,
    loop=true,
 }

 local soundParams2 = {
    timeOffset=0,
    volume=5,
    scale=false,
    pitch=1,
    loop=false,
 }
 local soundParams3 = {
    timeOffset=0,
    volume=1.5,
    scale=false,
    pitch=0.7,
    loop=false,
 }


 local function getCultAbilityMultiplier()
    return cultAbilityMultiplier
 end

 local function getResilienceTimeLeft()
    return resilienceTimeLeft
 end

 -- Ability function
 local function divineResilienceFunction(dt)
    --print('Каунтер считаем? ' ..gameTimeCounter)
    local currentHealth = types.Actor.stats.dynamic.health(self).current
    local maxHealth = types.Actor.stats.dynamic.health(self).base
    local currentHealthPercent = (currentHealth / maxHealth) * 100

    if healthLastFrame > currentHealth and currentHealthPercent <= 30 and not isImperialCultAbilityUsed and not isImperialCultAbilityCooldown then
        healthWasDamaged = true
        --print('В прошлом фрейме: ' .. healthLastFrame .. 'В этом фрейме: ' .. currentHealth)
    end
    
    healthLastFrame = currentHealth

    if healthWasDamaged and not isImperialCultAbilityCooldown and not isImperialCultAbilityUsed then
        isImperialCultAbilityUsed = true
        healthWasDamaged = false
        gameTimeLastFrame = core.getGameTime()
        --ambient.playSound("Thunder2", soundParams2)
        ambient.playSoundFile("Sound\\spell_sound.mp3", soundParams2)
        --ambient.playSound("sprigganmagic", soundParams2)
        ambient.playSound("Water Layer", soundParams)
        isAbilityWorking = true
        local imperialAbilityRank = NPC.getFactionRank(self, "imperial cult")
            if imperialAbilityRank > 0 then
                for _, rankInfo in ipairs(I.IMRGUILDS.ImperialCultGuildRanks) do
                    if imperialAbilityRank == rankInfo.rank then
                        cultAbilityMultiplier = rankInfo.multiplier + I.IMRART.getArtifactBonuses().abilPower

                        break  -- Stop iterating once the player's rank is found
                    end
                end
            end
        ui.showMessage("You've been blessed by Divine Resilience!\n\nMagicka Regeneration speed: +" .. cultAbilityMultiplier * 100 ..'%')
    end
    
    -- Check if the ability is currently in use
    if isImperialCultAbilityUsed then

        gameTimeCurrentFrame = core.getGameTime()
        gameTimeDifference = gameTimeCurrentFrame - gameTimeLastFrame
        gameTimeCounter = gameTimeCounter + gameTimeDifference
        gameTimeLastFrame = core.getGameTime()
        --print('Считаем время действия!: ' ..gameTimeCounter)
        resilienceTimeLeft = resilienceAbilityTime * 30 - gameTimeCounter
        --print('Времени абилки осталось: ' ..resilienceTimeLeft)
    
        -- Check if the ability duration is over
        if gameTimeCounter >= resilienceAbilityTime * 30 then
            local excessTime = gameTimeCounter - resilienceAbilityTime * 30
            -- Trigger the cooldown
            gameTimeCounter = excessTime
            isAbilityWorking = false
            ambient.stopSound("Water Layer");
            cultAbilityMultiplier = 0
            isImperialCultAbilityCooldown = true
            isImperialCultAbilityUsed = false
            --divineResilienceAbilityTimer = 0 -- Reset ability timer
            ui.showMessage('Divine Resilience expires')
        end
    end
    -- Check if the ability is on cooldown
    if isImperialCultAbilityCooldown then
        --divineResilienceCooldownTimer = divineResilienceCooldownTimer + dt
        --print(divineResilienceCooldownTimer)
        -- Check if the cooldown duration is over
        gameTimeCurrentFrame = core.getGameTime()
        gameTimeDifference = gameTimeCurrentFrame - gameTimeLastFrame
        gameTimeCounter = gameTimeCounter + gameTimeDifference
        gameTimeLastFrame = core.getGameTime()
        --print('Считаем время кулдауна!: ' ..gameTimeCounter)

        local cooldownArtifactBonus = I.IMRART.getArtifactBonuses().abilTime or 0
        --print('Абилка получена? ' ..cooldownArtifactBonus)
        --print ('Секунд кулдауна: ' ..resilienceCooldownTime - cooldownArtifactBonus)
        --local gameTimeDifference = (gameTimeCurrentFrame - gameTimeLastFrame) / 30
        --print('Времени прошло за тик: ' ..gameTimeDifference)
        if gameTimeCounter >= (resilienceCooldownTime - cooldownArtifactBonus) * 30 then
            
            gameTimeCounter = 0
            resilienceTimeLeft = 0
            isImperialCultAbilityCooldown = false
            divineResilienceCooldownTimer = 0
            ui.showMessage('Divine Resilience is ready')
        end
    end
end


local function onUpdate(dt)
    -- Divine Resilience of Imperial Cult ability
    tick_counter = tick_counter + dt

    if tick_counter >= tick_time then
        if settings.guilds:get('NMRGuildsImperialCult') then
            local playerImperialCultRank = NPC.getFactionRank(self, "imperial cult")
            if playerImperialCultRank > 0 then
                
                divineResilienceFunction(dt)

                --if isAbilityWorking == true then
                    --gameTimer(howMuchTime)
                --end
                
                
            end
        end
        tick_counter = 0
    end
end

local function onSave()
    return {
        healthWasDamaged = healthWasDamaged,
        isImperialCultAbilityUsed = isImperialCultAbilityUsed,
        isImperialCultAbilityCooldown = isImperialCultAbilityCooldown,
        cultAbilityMultiplier = cultAbilityMultiplier,
        divineResilienceAbilityTimer = divineResilienceAbilityTimer,
        divineResilienceCooldownTimer = divineResilienceCooldownTimer,
        healthLastFrame = healthLastFrame,
        gameTimeCounter = gameTimeCounter,
        gameTimeCurrentFrame = gameTimeCurrentFrame,
        gameTimeDifference = gameTimeDifference,
        gameTimeLastFrame = gameTimeLastFrame,
    }
  end

local function onLoad(data)
    if data then
        healthWasDamaged = data.healthWasDamaged or false
        isImperialCultAbilityUsed = data.isImperialCultAbilityUsed or false
        isImperialCultAbilityCooldown = data.isImperialCultAbilityCooldown or false
        cultAbilityMultiplier = data.cultAbilityMultiplier or 0
        divineResilienceAbilityTimer = data.divineResilienceAbilityTimer or 0
        divineResilienceCooldownTimer = data.divineResilienceCooldownTimer or 0
        healthLastFrame = data.healthLastFrame or types.Actor.stats.dynamic.health(self).current
        gameTimeCounter = data.gameTimeCounter or 0
        gameTimeCurrentFrame = data.gameTimeCurrentFrame or 0
        gameTimeDifference = data.gameTimeDifference or 0
        gameTimeLastFrame =  data.gameTimeLastFrame or core.getGameTime()
        --print('Каунтер загружен? ' ..gameTimeCounter)
    end
end

return {
    engineHandlers = {
        dt = dt,
        onUpdate = onUpdate,
        onLoad = onLoad,
        onSave = onSave,
        data = data,
    },
    interfaceName = "IMR_ABIL_RESIL",
    interface = {
        cultAbilityMultiplier = getCultAbilityMultiplier,
        resilienceTimeLeft = getResilienceTimeLeft,
    },
    
}


