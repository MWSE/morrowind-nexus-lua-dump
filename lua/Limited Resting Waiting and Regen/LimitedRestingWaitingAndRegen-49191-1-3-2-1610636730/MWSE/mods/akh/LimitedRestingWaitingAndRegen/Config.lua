local modInfo = require('akh.LimitedRestingWaitingAndRegen.ModInfo')

return mwse.loadConfig(modInfo.modName, {
    restingPreset = 1,
    contextualRestButtonPreset = 1,
    waitingPreset = 2,
    healthRegenPreset = 1,
    magickaRegenPreset = 1,
    morningHour = 6,
    untilMorningButtonText = "Until Morning",
    eveningHour = 18,
    untilEveningButtonText = "Until Evening",
    restingWaitingAntiSpam = true
})