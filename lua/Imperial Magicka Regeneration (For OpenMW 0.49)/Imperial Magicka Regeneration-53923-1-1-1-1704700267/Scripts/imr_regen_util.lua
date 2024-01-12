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


--Settings
local settings = {
    main = storage.playerSection('NMRSettingsA'),
    additions = storage.playerSection('NMRSettingsB'),
    guilds = storage.playerSection('NMRSettingsGuildsPage'),
}

function calculateRegenAmount(maxMagicka, regenStat, tick_time, oneSecond)
    -- Add your common calculation logic here
    -- For example, you can include guild bonuses, fatigue, etc.
    -- ...
    local BASE_REGEN_TIME = settings.main:get('NMRbaseRegenTime')
    local FAST_REGEN_TIME = settings.main:get('NMRfastRegenTime')

    local regenTime = ((BASE_REGEN_TIME - FAST_REGEN_TIME) / 99) * (100 - regenStat) + FAST_REGEN_TIME

        --Clamping values to be sure that they are not higher or lower than our base values
    regenTime = math.max(FAST_REGEN_TIME, math.min(BASE_REGEN_TIME, regenTime))

    local regenPercent = (tick_time / oneSecond) / regenTime
    regenAmount = maxMagicka * regenPercent

    return regenAmount, regenTime
end

function calculateMaxRegenAmount(maxMagicka, fortifyMagicka)
    -- ADDING BONUS TO MAX REGENERATION % BASED ON MAGE GUILD BONUS
    local maxRegenPercentage = settings.main:get('NMRMaxRegenPercentage') / 100
    if settings.guilds:get('NMRGuildsMages') then
        if I.IMRGUILDS.magesGuildBonus() > 0 then
            maxRegenPercentage = math.min(maxRegenPercentage + I.IMRGUILDS.magesGuildBonus(), 1)
            --print('Теперь максимальный процент регенерации составляет: ' , maxRegenPercentage)
        end
    end
    maxRegenPercentage = math.min(math.max(maxRegenPercentage + I.IMRART.getArtifactBonuses().regenPercent, 0), 1)
    --print('Max regen %: ' ..maxRegenPercentage)
    maxMagicka = maxMagicka + fortifyMagicka
    --Calculating max amount of magicka to regenerate based on the settings
    maxRegenerableMagicka = maxMagicka * maxRegenPercentage
    --print('Максимальное значение магии для регенерации: ' .. maxRegenerableMagicka)
    return maxRegenerableMagicka

end

return {
    interfaceName = "IMRRegenUtil",
    interface = {
        calculateRegenAmount = calculateRegenAmount,
        calculateMaxRegenAmount = calculateMaxRegenAmount,
    },
}