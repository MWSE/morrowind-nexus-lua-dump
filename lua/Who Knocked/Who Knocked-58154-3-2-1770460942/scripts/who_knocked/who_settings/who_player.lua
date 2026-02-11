-- Who Knocked Player Script - Settings Handler
-- Handles settings changes and sends events to global script

local core = require("openmw.core")
local storage = require("openmw.storage")
local async = require("openmw.async")

-- Get all settings storage groups
local mainGroup = storage.playerSection("SettingsWhoKnocked_Main")
local lockpickGroup = storage.playerSection("SettingsWhoKnocked_Lockpick")
local dialogueGroup = storage.playerSection("SettingsWhoKnocked_Dialogue")
local crimeGroup = storage.playerSection("SettingsWhoKnocked_Crime")
local uiGroup = storage.playerSection("SettingsWhoKnocked_UI")

-- Send individual settings functions
local function sendMainSettings()
    local settings = {
        enableWhoKnocked = mainGroup:get("enableWhoKnocked") ~= false
    }
    core.sendGlobalEvent("WhoKnocked_MainSettingsChanged", settings)
end

local function sendLockpickSettings()
    local settings = {
        enableLockpickSystem = lockpickGroup:get("enableLockpickSystem") ~= false,
        skillDifficultyModifier = lockpickGroup:get("skillDifficultyModifier") or 1.0
    }
    core.sendGlobalEvent("WhoKnocked_LockpickSettingsChanged", settings)
end

local function sendDialogueSettings()
    local settings = {
        enableDialogueSystem = dialogueGroup:get("enableDialogueSystem") ~= false,
        dialogueDifficultyModifier = dialogueGroup:get("dialogueDifficultyModifier") or 1.0
    }
    core.sendGlobalEvent("WhoKnocked_DialogueSettingsChanged", settings)
end

local function sendCrimeSettings()
    local settings = {
        enableCrimeSystem = crimeGroup:get("enableCrimeSystem") ~= false,
        bountyMultiplier = crimeGroup:get("bountyMultiplier") or 1.0
    }
    core.sendGlobalEvent("WhoKnocked_CrimeSettingsChanged", settings)
end

local function sendUISettings()
    local settings = {
        showSuccessMessages = uiGroup:get("showSuccessMessages") ~= false,
        messageDisplayTime = uiGroup:get("messageDisplayTime") or 3
    }
    core.sendGlobalEvent("WhoKnocked_UISettingsChanged", settings)
end

-- Subscribe to main settings changes
mainGroup:subscribe(async:callback(function(_, key)
    print("[WhoKnocked Settings] Main setting changed:", key)
    sendMainSettings()
end))

-- Subscribe to lockpick settings changes
lockpickGroup:subscribe(async:callback(function(_, key)
    print("[WhoKnocked Settings] Lockpick setting changed:", key)
    sendLockpickSettings()
end))

-- Subscribe to dialogue settings changes
dialogueGroup:subscribe(async:callback(function(_, key)
    print("[WhoKnocked Settings] Dialogue setting changed:", key)
    sendDialogueSettings()
end))

-- Subscribe to crime settings changes
crimeGroup:subscribe(async:callback(function(_, key)
    print("[WhoKnocked Settings] Crime setting changed:", key)
    sendCrimeSettings()
end))

-- Subscribe to UI settings changes
uiGroup:subscribe(async:callback(function(_, key)
    print("[WhoKnocked Settings] UI setting changed:", key)
    sendUISettings()
end))

-- Send all settings on startup
local function sendAllInitialSettings()
    print("[WhoKnocked Settings] Sending initial settings to global script")
    
    -- Send all settings groups
    sendMainSettings()
    sendLockpickSettings()
    sendDialogueSettings()
    sendCrimeSettings()
    sendUISettings()
end

-- Send initial settings immediately
sendAllInitialSettings()

print("[WhoKnocked Settings] Player settings handler loaded")
