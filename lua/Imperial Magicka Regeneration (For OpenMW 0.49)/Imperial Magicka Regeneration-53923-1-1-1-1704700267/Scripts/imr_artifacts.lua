local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local mwui = require('openmw.interfaces').MWUI
local input = require('openmw.input')
local NPC = require('openmw.types').NPC
local async = require('openmw.async')
local guilds = require('scripts.imr_guilds')

--Settings
local settings = {
    main = storage.playerSection('NMRSettingsA'),
    additions = storage.playerSection('NMRSettingsB'),
    guilds = storage.playerSection('NMRSettingsGuildsPage'),
}

local artifactMultiplier = 0
local artifactRegenPercent = 0
local artifactFatigue = 0
local artifactAbilTime = 0
local artifactAbilPower = 0
local artifactLowMultiplier = 0
local artifactLowMultiplierThreshold = 0
local artifactInitializerDelay = 0
local checkCounter = 0

--Timers to check equipped artifacts once per x frames
local artifactsCheckTime = 30
local artifactsCheckTimer = 0

--Timers to check artifacts to show notifications
local artifactsPopupTime = 60
local artifactsPopupTimer = 0

-- Artifacts that can speed up magicka regeneration
local artifactMultipliers = {
    {id = 'staff_magnus_unique', name = 'Staff of Magnus', multiplier = 0.10, maxRegen = 0.05, equipped = false, equippedThisFrame = false},
    {id = 'steelstaffancestors_ttsa', name = 'Ancestral Wisdom Staff', fatigueMult = 0.10, equipped = false, equippedThisFrame = false},
    {id = 'ebony_staff_trebonius', name = "Trebonius' Staff", lowMultiplier = 0.3, lowMultiplierThreshold = 0.20, maxRegen = -0.10, equipped = false, equippedThisFrame = false},
    {id = "ebony wizard's staff", name = "Wizard's Staff", multiplier = 0.07, maxRegen = 0.05, equipped = false, equippedThisFrame = false},
    {id = 'ebony_staff_tges', name = "Maryon's Staff", lowMultiplier = 0.4, lowMultiplierThreshold = 0.10, maxRegen = 0.10, equipped = false, equippedThisFrame = false},
    {id = 'ring_mentor_unique', name = 'Ring of Mentor', multiplier = 0.05, equipped = false, equippedThisFrame = false},
    {id = 'ring_warlock_unique', name = 'Ring of Warlock', multiplier = 0.06, equipped = false, equippedThisFrame = false},
    {id = 'Akatosh Ring', name = "Akatosh's Ring", abilityTime = 60, equipped = false, equippedThisFrame = false},
    {id = 'Septim Ring', name = "Septim Ring", abilityPower = 1.5, equipped = false, equippedThisFrame = false},
    {id = 'ring_equity_uniq', name = "Ring of Equity", maxRegen = 0.05, equipped = false, equippedThisFrame = false},
    {id = 'necromancers_amulet_uniq', name = 'Amulet of the Necromancer', multiplier = 0.10, equipped = false, equippedThisFrame = false},
    {id = 'hortatorbelt', name = 'Belt of the Hortator', multiplier = 0.03, equipped = false, equippedThisFrame = false},
    {id = 'amulet_unity_uniq', name = 'Amulet of Unity', multiplier = 0.08, equipped = false, equippedThisFrame = false},
    {id = "exquisite_robe_drake's pride", name = "Robe of the Drake's Pride", equipped = false, multiplier = 0.10, equippedThisFrame = false},
    {id = "artifact_amulet of heartthrum", name = "Amulet of Heartthrum", equipped = false, multiplier = 0.08, equippedThisFrame = false},
}

-- Looking for equipped items
local function hasItemIDEquipped(itemID)
    local item = types.Actor.inventory(self):find(itemID)
    return item and types.Actor.hasEquipped(self, item)
end

local function equippedBonusMessage(name, bonuses)
    local message = name .. ':\n\n'
    for bonusType, value in pairs(bonuses) do
        if value ~= 0 then
            local bonusString = ''
            if bonusType == 'multiplier' then
                bonusString = 'Your Magicka regenerates ' .. value * 100 .. '% faster.'
            elseif bonusType == 'regenPercent' then
                bonusString = (value >= 0 and '+' or '') .. value * 100 .. '% to your total regenerable Magicka.'
            elseif bonusType == 'fatigueMult' then
                bonusString = 'Your Fatigue penalty to Magicka Regeneration reduced by ' .. value * 100 .. '%.'
            elseif bonusType == 'abilityTime' then
                bonusString = 'Divine Resilience ability recovers ' .. value .. ' seconds faster.'
            elseif bonusType == 'abilityPower' then
                bonusString = 'Divine Resilience ability multiplier is ' .. value * 100 .. '% higher.'
            elseif bonusType == 'lowMultiplier' then
                bonusString = 'Magicka regeneration speed with low Magicka (less than ' .. bonuses.lowMultiplierThreshold * 100 .. '%) is ' .. value * 100 .. '% faster.'
            -- Add more bonuses as needed
            end
            message = message .. bonusString .. '\n'
        end
    end
    ui.showMessage(message)
end

local function artifactsInitializer()
    for _, artifact in ipairs(artifactMultipliers) do
        if hasItemIDEquipped(artifact.id) then
            artifact.equipped = true
        end
    end
end

local function getArtifactBonuses()
    return {
        multiplier = artifactMultiplier,
        lowMultiplier = artifactLowMultiplier,
        regenPercent = artifactRegenPercent,
        fatigue = artifactFatigue,
        abilTime = artifactAbilTime,
        abilPower = artifactAbilPower,
        lowMultThresh = artifactLowMultiplierThreshold,
        -- Add more bonuses as needed
    }
end

local function getArtifactMultiplier()
    return artifactMultiplier
end

local function calculateArtifactBonuses()
    artifactMultiplier = 0
    artifactLowMultiplier = 0
    artifactRegenPercent = 0
    artifactFatigue = 0
    artifactAbilTime = 0
    artifactAbilPower = 0
    artifactLowMultiplierThreshold = 0
    for _, artifact in ipairs(artifactMultipliers) do
        if hasItemIDEquipped(artifact.id) then
            artifactMultiplier = artifactMultiplier + (artifact.multiplier or 0)
            artifactRegenPercent = artifactRegenPercent + (artifact.maxRegen or 0)
            artifactFatigue = artifactFatigue + (artifact.fatigueMult or 0)
            artifactAbilTime = artifactAbilTime + (artifact.abilityTime or 0)
            artifactAbilPower = artifactAbilPower + (artifact.abilityPower or 0)
            artifactLowMultiplier = artifactLowMultiplier + (artifact.lowMultiplier or 0)
            artifactLowMultiplierThreshold = artifactLowMultiplierThreshold + (artifact.lowMultiplierThreshold or 0)
            --print('В функции с артефактами:' .. artifactMultiplier)                  
        end
    end
    return artifactMultiplier, artifactRegenPercent, artifactFatigue, artifactAbilTime, artifactAbilPower, artifactLowMultiplier, artifactLowMultiplierThreshold

end

local function onUpdate(dt)
    --artifactMultiplier = 1
    artifactsCheckTimer = artifactsCheckTimer + 1
        if artifactsCheckTimer > artifactsCheckTime then
            --print(I.IMRGUILDS.magesGuildBonus())
            --print(artifactMultiplier)
            if settings.additions:get('NMRArtMultiplier') then
                artifactMultiplier, artifactRegenPercent, artifactFatigue, artifactAbilTime, artifactAbilPower, artifactLowMultiplier, artifactLowMultiplierThreshold = calculateArtifactBonuses()
                --print("Artifact Multiplier:", artifactMultiplier)
                --print("Artifact Regen Percent:", artifactRegenPercent)
                --print("Artifact Fatigue:", artifactFatigue)
                --print("Artifact Ability Time:", artifactAbilTime)
                --print("Artifact Ability Power:", artifactAbilPower)
                --print("Artifact Low Multiplier:", artifactLowMultiplier)
                --print("Artifact Low Threshold:", artifactLowMultiplierThreshold)
            end
            
        artifactsCheckTimer = 0
    end
end

local function onFrame(dt)

    --Initialize equipped artifacts once
    if artifactInitializerDelay < 1 then
        artifactsInitializer()
        artifactInitializerDelay = artifactInitializerDelay + 1
        return
    end

    artifactsPopupTimer = artifactsPopupTimer + 1
    
    --If an artifact was equipped this check, show message
    if settings.additions:get('NMRArtMultiplier') and artifactsPopupTimer > artifactsPopupTime then
        for _, artifact in ipairs(artifactMultipliers) do
            if not hasItemIDEquipped(artifact.id) then
                checkCounter = checkCounter + 1
                if checkCounter > 0 and not artifact.equipped then
                    checkCounter = 0
                end
                artifact.equipped = false
            elseif hasItemIDEquipped(artifact.id) then
                checkCounter = checkCounter + 1
                if checkCounter > 0 and not artifact.equipped then
                    checkCounter = 0
                    local bonuses = {
                        multiplier = (artifact.multiplier or 0),
                        lowMultiplier = (artifact.lowMultiplier or 0),
                        lowMultiplierThreshold = (artifact.lowMultiplierThreshold or 0),
                        regenPercent = (artifact.maxRegen or 0),
                        fatigueMult = (artifact.fatigueMult or 0),
                        abilityTime = (artifact.abilityTime or 0),
                        abilityPower = (artifact.abilityPower or 0),
                        -- Add more bonuses as needed
                    }
                    equippedBonusMessage(artifact.name, bonuses)
                end
                artifact.equipped = true
            end
        end
        artifactsPopupTimer = 0
    end
end

return {
    engineHandlers = {
        dt = dt,
        onUpdate = onUpdate,
        onFrame = onFrame,
    },
    interfaceName = "IMRART",
    interface = {
        getArtifactBonuses = getArtifactBonuses,
        getArtifactMultiplier = getArtifactMultiplier,
    },
    
}

