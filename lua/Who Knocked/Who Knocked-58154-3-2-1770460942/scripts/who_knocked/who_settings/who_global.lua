-- Who Knocked Global Script - Settings Receiver
-- Receives settings events and applies them to Who Knocked systems

local core = require("openmw.core")

-- Default settings values
local settings = {
    -- Main settings
    enableWhoKnocked = true,
    -- Lockpick settings
    enableLockpickSystem = true,
    skillDifficultyModifier = 1.0,
    -- Dialogue settings
    enableDialogueSystem = true,
    dialogueDifficultyModifier = 1.0,
    -- Crime settings
    enableCrimeSystem = true,
    bountyMultiplier = 1.0,
    -- UI settings
    showSuccessMessages = true,
    messageDisplayTime = 3
}

-- Helper function
local function msg(message)
    print("[WhoKnocked Settings] " .. message)
end

-- Public API for other Who Knocked scripts to get current settings
local function getSettings()
    return settings
end

-- Specific getter functions for convenience
local function isSystemEnabled()
    return settings.enableWhoKnocked
end

local function isLockpickEnabled()
    return settings.enableWhoKnocked and settings.enableLockpickSystem
end

local function isDialogueEnabled()
    return settings.enableWhoKnocked and settings.enableDialogueSystem
end

local function isCrimeEnabled()
    return settings.enableWhoKnocked and settings.enableCrimeSystem
end

local function getSkillDifficultyModifier()
    return settings.skillDifficultyModifier
end

local function getDialogueDifficultyModifier()
    return settings.dialogueDifficultyModifier
end

local function getBountyMultiplier()
    return settings.bountyMultiplier
end

local function shouldShowMessages()
    return settings.showSuccessMessages
end

local function getMessageDisplayTime()
    return settings.messageDisplayTime
end

-- Event handlers for settings changes
local eventHandlers = {
    WhoKnocked_MainSettingsChanged = function(newSettings)
        if newSettings.enableWhoKnocked ~= nil then 
            settings.enableWhoKnocked = newSettings.enableWhoKnocked
            msg("Main system " .. (settings.enableWhoKnocked and "ENABLED" or "DISABLED"))
        end
    end,
    
    WhoKnocked_LockpickSettingsChanged = function(newSettings)
        if newSettings.enableLockpickSystem ~= nil then 
            settings.enableLockpickSystem = newSettings.enableLockpickSystem
            msg("Lockpick system " .. (settings.enableLockpickSystem and "ENABLED" or "DISABLED"))
        end
        if newSettings.skillDifficultyModifier then 
            settings.skillDifficultyModifier = newSettings.skillDifficultyModifier
            msg("Skill difficulty modifier: " .. settings.skillDifficultyModifier)
        end
    end,
    
    WhoKnocked_DialogueSettingsChanged = function(newSettings)
        if newSettings.enableDialogueSystem ~= nil then 
            settings.enableDialogueSystem = newSettings.enableDialogueSystem
            msg("Dialogue system " .. (settings.enableDialogueSystem and "ENABLED" or "DISABLED"))
        end
        if newSettings.dialogueDifficultyModifier then 
            settings.dialogueDifficultyModifier = newSettings.dialogueDifficultyModifier
            msg("Dialogue difficulty modifier: " .. settings.dialogueDifficultyModifier)
        end
    end,
    
    WhoKnocked_CrimeSettingsChanged = function(newSettings)
        if newSettings.enableCrimeSystem ~= nil then 
            settings.enableCrimeSystem = newSettings.enableCrimeSystem
            msg("Crime system " .. (settings.enableCrimeSystem and "ENABLED" or "DISABLED"))
        end
        if newSettings.bountyMultiplier then 
            settings.bountyMultiplier = newSettings.bountyMultiplier
            msg("Bounty multiplier: " .. settings.bountyMultiplier)
        end
    end,
    
    WhoKnocked_UISettingsChanged = function(newSettings)
        if newSettings.showSuccessMessages ~= nil then 
            settings.showSuccessMessages = newSettings.showSuccessMessages
            msg("Result messages " .. (settings.showSuccessMessages and "ENABLED" or "DISABLED"))
        end
        if newSettings.messageDisplayTime then 
            settings.messageDisplayTime = newSettings.messageDisplayTime
            msg("Message display time: " .. settings.messageDisplayTime .. " seconds")
        end
    end,
    
    -- Query events from menu system - send responses back to player
    WhoKnocked_QueryLockpickEnabled = function(data)
        msg("Query: Lockpick system is " .. (settings.enableLockpickSystem and "ENABLED" or "DISABLED"))
        -- Send response back to player script
        if data.door and data.actor then
            data.actor:sendEvent("WhoKnocked_LockpickQueryResponse", {
                enabled = settings.enableLockpickSystem,
                door = data.door
            })
        end
    end,
    
    WhoKnocked_QueryDialogueEnabled = function(data)
        msg("Query: Dialogue system is " .. (settings.enableDialogueSystem and "ENABLED" or "DISABLED"))
        -- Send response back to player script
        if data.door and data.actor then
            data.actor:sendEvent("WhoKnocked_DialogueQueryResponse", {
                enabled = settings.enableDialogueSystem,
                door = data.door
            })
        end
    end
}

-- Expose interface for other scripts to query settings
return {
    interfaceName = "WhoKnockedGlobal",
    interface = {
        version = 1,
        getSettings = getSettings
    },
    engineHandlers = {
        -- Add any engine handlers if needed
    },
    eventHandlers = eventHandlers
}
