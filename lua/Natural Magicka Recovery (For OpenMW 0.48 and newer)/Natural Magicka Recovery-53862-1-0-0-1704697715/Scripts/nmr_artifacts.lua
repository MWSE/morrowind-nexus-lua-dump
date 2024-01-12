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

--Settings
local settings = {
    base = storage.playerSection('NMRSettingsA'),
    addons = storage.playerSection('NMRSettingsB'),
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
    {id = 'staff_magnus_unique', name = 'Staff of Magnus', multiplier = 0.15, maxRegen = 0.10, equipped = false, equippedThisFrame = false},
    {id = 'steelstaffancestors_ttsa', name = 'Ancestral Wisdom Staff', fatigueMult = 0.15, equipped = false, equippedThisFrame = false},
    {id = 'ebony_staff_trebonius', name = "Trebonius' Staff", lowMultiplier = 0.3, lowMultiplierThreshold = 0.20, maxRegen = -0.10, equipped = false, equippedThisFrame = false},
    {id = "ebony wizard's staff", name = "Wizard's Staff", multiplier = 0.10, maxRegen = 0.05, equipped = false, equippedThisFrame = false},
    {id = 'ebony_staff_tges', name = "Maryon's Staff", lowMultiplier = 0.4, lowMultiplierThreshold = 0.10, maxRegen = 0.15, equipped = false, equippedThisFrame = false},
    {id = 'ring_mentor_unique', name = 'Ring of Mentor', maxRegen = 0.05, equipped = false, equippedThisFrame = false},
    {id = 'ring_warlock_unique', name = 'Ring of Warlock', multiplier = 0.06, equipped = false, equippedThisFrame = false},
    {id = 'akatosh ring', name = "Akatosh's Ring", fatigueMult = 0.10, equipped = false, equippedThisFrame = false},
    {id = 'septim ring', name = "Septim Ring", fatigueMult = 0.05, equipped = false, equippedThisFrame = false},
    {id = 'ring_equity_uniq', name = "Ring of Equity", maxRegen = 0.05, equipped = false, equippedThisFrame = false},
    {id = 'necromancers_amulet_uniq', name = 'Amulet of the Necromancer', multiplier = 0.10, equipped = false, equippedThisFrame = false},
    {id = 'hortatorbelt', name = 'Belt of the Hortator', multiplier = 0.03, equipped = false, equippedThisFrame = false},
    {id = 'amulet_unity_uniq', name = 'Amulet of Unity', multiplier = 0.08, equipped = false, equippedThisFrame = false},
    {id = "exquisite_robe_drake's pride", name = "Robe of the Drake's Pride", equipped = false, multiplier = 0.10, equippedThisFrame = false},
    {id = "artifact_amulet of heartthrum", name = "Amulet of Heartthrum", equipped = false, multiplier = 0.08, equippedThisFrame = false},
}

-- Looking for equipped items
local function hasRecordIdEquipped(actor, recordId)
    local equipment = types.Actor.equipment(actor)
    for _, item in pairs(equipment) do
        if item.recordId == recordId then
            return true
        end
    end
    return false
end

local function equippedBonusMessage(name, bonuses)
    local message = name .. ':\n\n'

    local bonusCount = 0
    for bonusType, value in pairs(bonuses) do
        if bonusType ~= 'lowMultiplierThreshold' and value ~= 0 then
            local bonusString = ''
            bonusCount = bonusCount + 1
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

            if bonusCount > 1 then
                bonusString = '\n\n' .. bonusString
            end
            message = message .. bonusString
        end
    end
    ui.showMessage(message)
end

local function artifactsInitializer()
    for _, artifact in ipairs(artifactMultipliers) do
        if hasRecordIdEquipped(self, artifact.id) then
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
        if hasRecordIdEquipped(self, artifact.id) then
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
    if settings.base:get('NMRisActive') then
        artifactsCheckTimer = artifactsCheckTimer + 1
            if artifactsCheckTimer > artifactsCheckTime then
                --print(I.IMRGUILDS.magesGuildBonus())
                --print(artifactMultiplier)
                if settings.addons:get('NMRArtMultiplier') then
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
end

local function onFrame(dt)
    if settings.base:get('NMRisActive') then
    --Initialize equipped artifacts once
        if artifactInitializerDelay < 1 then
            artifactsInitializer()
            artifactInitializerDelay = artifactInitializerDelay + 1
            return
        end

        artifactsPopupTimer = artifactsPopupTimer + 1
        
        --If an artifact was equipped this check, show message
        if settings.addons:get('NMRArtMultiplier') and artifactsPopupTimer > artifactsPopupTime then
            for _, artifact in ipairs(artifactMultipliers) do
                if not hasRecordIdEquipped(self, artifact.id) then
                    checkCounter = checkCounter + 1
                    if checkCounter > 0 and not artifact.equipped then
                        checkCounter = 0
                    end
                    artifact.equipped = false
                elseif hasRecordIdEquipped(self, artifact.id) then
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
end

return {
    engineHandlers = {
        dt = dt,
        onUpdate = onUpdate,
        onFrame = onFrame,
    },
    interfaceName = "NMR_ART",
    interface = {
        getArtifactBonuses = getArtifactBonuses,
        getArtifactMultiplier = getArtifactMultiplier,
    },
    
}