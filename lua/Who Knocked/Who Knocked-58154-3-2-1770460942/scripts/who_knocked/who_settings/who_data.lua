-- Who Knocked Data Interface
-- Exports settings data to other Who Knocked scripts

return {
    interfaceName = "WhoKnockedData",
    interface = {
        version = 1,
        getMainSettings = function()
            -- Get main system settings
            local storage = require("openmw.storage")
            local group = storage.playerSection("SettingsWhoKnocked_Main")
            return {
                enableWhoKnocked = group:get("enableWhoKnocked") ~= false
            }
        end,
        getLockpickSettings = function()
            -- Get lockpick system settings
            local storage = require("openmw.storage")
            local group = storage.playerSection("SettingsWhoKnocked_Lockpick")
            return {
                enableLockpickSystem = group:get("enableLockpickSystem") ~= false,
                skillDifficultyModifier = group:get("skillDifficultyModifier") or 1.0
            }
        end,
        getDialogueSettings = function()
            -- Get dialogue system settings
            local storage = require("openmw.storage")
            local group = storage.playerSection("SettingsWhoKnocked_Dialogue")
            return {
                enableDialogueSystem = group:get("enableDialogueSystem") ~= false,
                dialogueDifficultyModifier = group:get("dialogueDifficultyModifier") or 1.0
            }
        end,
        getCrimeSettings = function()
            -- Get crime system settings
            local storage = require("openmw.storage")
            local group = storage.playerSection("SettingsWhoKnocked_Crime")
            return {
                enableCrimeSystem = group:get("enableCrimeSystem") ~= false,
                bountyMultiplier = group:get("bountyMultiplier") or 1.0
            }
        end,
        getUISettings = function()
            -- Get UI settings
            local storage = require("openmw.storage")
            local group = storage.playerSection("SettingsWhoKnocked_UI")
            return {
                showSuccessMessages = group:get("showSuccessMessages") ~= false,
                messageDisplayTime = group:get("messageDisplayTime") or 3
            }
        end,
        getAllSettings = function()
            -- Get all settings in one call
            local storage = require("openmw.storage")
            local mainGroup = storage.playerSection("SettingsWhoKnocked_Main")
            local lockpickGroup = storage.playerSection("SettingsWhoKnocked_Lockpick")
            local dialogueGroup = storage.playerSection("SettingsWhoKnocked_Dialogue")
            local crimeGroup = storage.playerSection("SettingsWhoKnocked_Crime")
            local uiGroup = storage.playerSection("SettingsWhoKnocked_UI")
            
            return {
                -- Main settings
                enableWhoKnocked = mainGroup:get("enableWhoKnocked") ~= false,
                -- Lockpick settings
                enableLockpickSystem = lockpickGroup:get("enableLockpickSystem") ~= false,
                skillDifficultyModifier = lockpickGroup:get("skillDifficultyModifier") or 1.0,
                -- Dialogue settings
                enableDialogueSystem = dialogueGroup:get("enableDialogueSystem") ~= false,
                dialogueDifficultyModifier = dialogueGroup:get("dialogueDifficultyModifier") or 1.0,
                -- Crime settings
                enableCrimeSystem = crimeGroup:get("enableCrimeSystem") ~= false,
                bountyMultiplier = crimeGroup:get("bountyMultiplier") or 1.0,
                -- UI settings
                showSuccessMessages = uiGroup:get("showSuccessMessages") ~= false,
                messageDisplayTime = uiGroup:get("messageDisplayTime") or 3
            }
        end
    }
}
