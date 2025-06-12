local input_module = require('openmw.input')
local storage_module = require('scripts.TwentyTwentyObjects.util.storage')
local core_module = require('openmw.core') -- For sendGlobalEvent
local logger_module = require('scripts.TwentyTwentyObjects.util.logger')

-- Forward declare generalSettings for logger
local generalSettings = {}

-- Helper: Create a clean, serializable copy of a profile
local function cleanProfile(profile)
    if not profile then return nil end
    return {
        name = profile.name or "",
        key = profile.key or "",
        shift = profile.shift or false,
        ctrl = profile.ctrl or false,
        alt = profile.alt or false,
        radius = profile.radius or 1000,
        modeToggle = profile.modeToggle or false,
        filters = {
            items = profile.filters and profile.filters.items or false,
            weapons = profile.filters and profile.filters.weapons or false,
            armor = profile.filters and profile.filters.armor or false,
            clothing = profile.filters and profile.filters.clothing or false,
            books = profile.filters and profile.filters.books or false,
            ingredients = profile.filters and profile.filters.ingredients or false,
            misc = profile.filters and profile.filters.misc or false,
            npcs = profile.filters and profile.filters.npcs or false,
            creatures = profile.filters and profile.filters.creatures or false,
            containers = profile.filters and profile.filters.containers or false,
            doors = profile.filters and profile.filters.doors or false
        }
    }
end

-- Helper: Check if a key event matches a profile's hotkey
local function isProfileHotkey(profile, keyEvent)
    if not profile or not profile.key or not keyEvent or not keyEvent.symbol then
        -- logger_module.debug("[HotkeyListener] isProfileHotkey: Invalid profile or keyEvent data.")
        return false
    end
    return (keyEvent.symbol == profile.key and
            (keyEvent.withShift == (profile.shift or false)) and
            (keyEvent.withCtrl == (profile.ctrl or false)) and
            (keyEvent.withAlt == (profile.alt or false)))
end

local function onKeyPress(keyEvent)
    -- Profiles are loaded here to ensure the latest version is used on each key press.
    -- This avoids issues if profiles change in settings menu while game is running.
    local currentProfiles = storage_module.getProfiles()
    if not currentProfiles or #currentProfiles == 0 then
        -- logger_module.debug("[HotkeyListener] onKeyPress: No profiles loaded.")
        return
    end

    -- logger_module.debug("[HotkeyListener] KeyPress: " .. keyEvent.symbol)

    for _, profile in ipairs(currentProfiles) do
        if isProfileHotkey(profile, keyEvent) then
            -- logger_module.debug("[HotkeyListener] Matched profile: " .. profile.name)
            local cleanedProfile = cleanProfile(profile)
            core_module.sendGlobalEvent("TTO_GlobalKeyEvent", { eventType = "press", profile = cleanedProfile })
            return -- Process only the first matched profile
        end
    end
end

local function onKeyRelease(keyEvent)
    local currentProfiles = storage_module.getProfiles()
    if not currentProfiles or #currentProfiles == 0 then
        return
    end

    -- logger_module.debug("[HotkeyListener] KeyRelease: " .. keyEvent.symbol)

    for _, profile in ipairs(currentProfiles) do
        if isProfileHotkey(profile, keyEvent) then
            -- logger_module.debug("[HotkeyListener] Matched profile for release: " .. profile.name)
            local cleanedProfile = cleanProfile(profile)
            core_module.sendGlobalEvent("TTO_GlobalKeyEvent", { eventType = "release", profile = cleanedProfile })
            return -- Process only the first matched profile
        end
    end
end

local function onLoad()
    -- local engine_storage = require('openmw.storage') -- No longer needed here
    -- storage_module.init(engine_storage) -- No longer needed here

    generalSettings = storage_module.get('general', { debug = false })
    logger_module.init(generalSettings.debug)
    logger_module.info("[HotkeyListener] Script loaded and initialized.")
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
        onKeyRelease = onKeyRelease,
        onLoad = onLoad
    }
} 