--[[
    ArcaneWard/config.lua

    Stores default settings and loads the user's saved MWSE config.
]]

local configPath = "ArcaneWard"

local defaultConfig = {
    enabled = true,

    minUnarmored = 10,
    minAlteration = 20,

    maxChance = 35,

    allowMagicDamage = false,
    onlyCombatDamage = true,

    showInStatsMenu = true,

    applyToPlayer = true,
    applyToNPCs = false,
    applyToCreatures = false,

    playProcSound = true,
    procSoundId = "alteration hit",

    playProcVFX = true,
    procVFXId = "VFX_ShieldHit",
    procVFXDuration = 0.35,

    debug = false,
    debugMessages = false,
}

local config = mwse.loadConfig(configPath, defaultConfig)

if config.debugMessages == nil then
    config.debugMessages = defaultConfig.debugMessages
end

if config.minAlteration == nil then
    config.minAlteration = defaultConfig.minAlteration
end

if config.onlyCombatDamage == nil then
    config.onlyCombatDamage = defaultConfig.onlyCombatDamage
end

if config.playProcSound == nil then
    config.playProcSound = defaultConfig.playProcSound
end

if config.procSoundId == nil then
    config.procSoundId = defaultConfig.procSoundId
end

if config.playProcVFX == nil then
    config.playProcVFX = defaultConfig.playProcVFX
end

if config.procVFXId == nil then
    config.procVFXId = defaultConfig.procVFXId
end

if config.procVFXDuration == nil then
    config.procVFXDuration = defaultConfig.procVFXDuration
end

if config.applyToPlayer == nil then
    config.applyToPlayer = defaultConfig.applyToPlayer
end

if config.applyToNPCs == nil then
    config.applyToNPCs = defaultConfig.applyToNPCs
end

if config.applyToCreatures == nil then
    config.applyToCreatures = defaultConfig.applyToCreatures
end

return {
    path = configPath,
    default = defaultConfig,
    current = config,
}