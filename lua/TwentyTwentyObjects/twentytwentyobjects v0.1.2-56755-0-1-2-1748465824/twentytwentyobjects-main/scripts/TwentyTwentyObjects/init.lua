-- init.lua: Global script for Twenty Twenty Objects Mod
-- Handles profile management and player events

local world = require('openmw.world')
local async = require('openmw.async')
local core = require('openmw.core') -- ENSURE THIS IS PRESENT AND UNCOMMENTED
local types = require('openmw.types') -- Added for sendMenuEvent
print("[TTO DEBUG INIT.LUA] Right after require - openmw.async type: " .. type(async) .. ", value: " .. tostring(async))
local storage_module = require('scripts.TwentyTwentyObjects.util.storage')
local logger_module = require('scripts.TwentyTwentyObjects.util.logger')

print("[TTO DEBUG] INIT.LUA: Script parsing started.")

-- Script-level variables (formerly in onLoad)
local profiles = {}
local activeProfileName = nil -- This will reset on game load/script reload for now
local momentaryActiveProfileName = nil -- This will reset on game load/script reload for now
local generalSettings = {}

-- Helper: Create clean, serializable copies of our data structures
-- This is safer than trying to convert arbitrary userdata
local function cleanFilters(filters)
    if not filters then return {} end
    -- Explicitly copy each known filter
    return {
        items = filters.items or false,
        weapons = filters.weapons or false,
        armor = filters.armor or false,
        clothing = filters.clothing or false,
        books = filters.books or false,
        ingredients = filters.ingredients or false,
        misc = filters.misc or false,
        npcs = filters.npcs or false,
        creatures = filters.creatures or false,
        containers = filters.containers or false,
        doors = filters.doors or false
    }
end

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
        filters = cleanFilters(profile.filters)
    }
end

local function cleanProfiles(profileList)
    local clean = {}
    if profileList then
        for i, profile in ipairs(profileList) do
            clean[i] = cleanProfile(profile)
        end
    end
    return clean
end

local function cleanSettings(settings, defaults)
    if not settings then return defaults or {} end
    local clean = {}
    -- Only copy what we know should exist
    for k, v in pairs(defaults or {}) do
        if type(v) == "table" then
            clean[k] = cleanSettings(settings[k], v)
        else
            clean[k] = settings[k] or v
        end
    end
    return clean
end

-- Initial Setup (runs once when script is loaded by the engine)
print("[TTO DEBUG] INIT.LUA: Performing initial setup...")
generalSettings = storage_module.get('general', { debug = false })
logger_module.init(generalSettings.debug)
logger_module.info("[Global] Logger initialized during top-level setup.")

storage_module.initializeDefaults()
local storedProfiles = storage_module.getProfiles()
profiles = cleanProfiles(storedProfiles) -- Convert to clean Lua tables
logger_module.info(string.format('[Global] Loaded %d profiles during top-level setup.', #profiles))

-- Default settings structures
local defaultAppearance = {
    labelStyle = "native",
    textSize = "medium",
    lineStyle = "straight",
    lineColor = {r=0.8, g=0.8, b=0.8, a=0.7},
    backgroundColor = {r=0, g=0, b=0, a=0.5},
    showIcons = true,
    enableAnimations = true,
    animationSpeed = "normal",
    fadeDistance = true,
    groupSimilar = false,
    opacity = 0.8
}

local defaultPerformance = {
    maxLabels = 20,
    updateInterval = "medium",
    scanInterval = "medium",
    distanceCulling = true,
    cullDistance = 2000,
    occlusionChecks = "basic",
    smartGrouping = false
}

-- Send event to prompt settings menu to refresh
print("[TTO DEBUG] INIT.LUA: Sending PleaseRefreshSettingsEvent...")
local dataToRefreshWith = {
    profiles    = profiles, -- Already clean
    appearance  = cleanSettings(storage_module.get('appearance'), defaultAppearance),
    performance = cleanSettings(storage_module.get('performance'), defaultPerformance),
    general     = cleanSettings(generalSettings, { debug = false })
}
-- Don't log the table as it might contain non-serializable data
logger_module.info('[Global] Preparing data for PleaseRefreshSettingsEvent')

local player = world.players[1]
if player then
    logger_module.info("[Global] Sending PleaseRefreshSettingsEvent to MENU script via player event.")
    types.Player.sendMenuEvent(player, "PleaseRefreshSettingsEvent", { dataToRefreshWith = dataToRefreshWith })
else
    logger_module.warn("[Global] No player found, cannot send PleaseRefreshSettingsEvent to menu.")
end
-- core.sendGlobalEvent("PleaseRefreshSettingsEvent", { dataToRefreshWith = dataToRefreshWith }) -- Old method, commented out
logger_module.info("[Global] Event dispatch attempt for PleaseRefreshSettingsEvent finished.")

-- Storage Subscription
print("[TTO DEBUG] INIT.LUA: Setting up storage subscription...")
if async and async.callback then -- Check if async and async.callback are valid before using
    storage_module.subscribe(async:callback(function(section, key)
        logger_module.debug("[Global] Storage changed. Section: " .. tostring(section) .. ", Key: " .. tostring(key))
        if key == 'profiles' or key == nil then -- if key is nil, means a batch update or unknown change, reload all
            local storedProfiles = storage_module.getProfiles()
            profiles = cleanProfiles(storedProfiles) -- Update module-level profiles table
            logger_module.info('[Global] Profiles reloaded from storage due to subscription. Count: ' .. #profiles)
            
            if activeProfileName then -- Check if the currently active toggle profile still exists
                local stillExists = false
                for _, p in ipairs(profiles) do
                    if p.name == activeProfileName then
                        stillExists = true
                        break
                    end
                end
                if not stillExists then
                    logger_module.info("[Global] Active profile '" .. activeProfileName .. "' no longer exists. Hiding highlights.")
                    sendToPlayerRenderer('TTO_HideHighlights', {})
                    activeProfileName = nil
                    momentaryActiveProfileName = nil -- Also reset momentary if the main toggle was removed
                end
            end
        elseif key == 'general' or key == nil then
            local newGeneralSettings = storage_module.get('general', { debug = false })
            if newGeneralSettings.debug ~= generalSettings.debug then
                generalSettings.debug = newGeneralSettings.debug
                logger_module.init(generalSettings.debug)
                logger_module.info("[Global] Logger debug state updated via subscription to: " .. tostring(generalSettings.debug))
            end
        end
    end))
    logger_module.info("[Global] Storage subscription setup complete.")
else
    logger_module.warn("[Global] Could not set up storage subscription because 'async' or 'async.callback' is nil at this point.")
end

logger_module.info("[Global] Top-level setup complete. Script is active and listening for events.")
print("[TTO DEBUG] INIT.LUA: Top-level setup finished.")

-- Helper: Send event to player (rendering scripts)
local function sendToPlayerRenderer(event, data)
    -- To send events to PLAYER scripts from GLOBAL, we need to iterate through players
    for _, player in ipairs(world.players) do
        player:sendEvent(event, data)
    end
    logger_module.debug(string.format('[Global] Sent event %s to all player scripts with data: %s', event, tostring(data)))
end

-- Event handler for key events from HotkeyListener
local function onGlobalKeyEvent(data) 
    logger_module.debug("[Global] Received TTO_GlobalKeyEvent: type=" .. data.eventType .. ", profile=" .. (data.profile and data.profile.name or "Unknown Profile"))
    if not data.profile then
        logger_module.warn("[Global] TTO_GlobalKeyEvent received without profile data.")
        return
    end

    local profile = data.profile
    local eventType = data.eventType

    if eventType == "press" then
        if profile.modeToggle then 
            if activeProfileName == profile.name then 
                sendToPlayerRenderer('TTO_HideHighlights', {})
                activeProfileName = nil
                logger_module.info('[Global] Toggle OFF for profile: ' .. profile.name)
            else 
                if activeProfileName then 
                    sendToPlayerRenderer('TTO_HideHighlights', {})
                end
                sendToPlayerRenderer('TTO_ShowHighlights', { profile = cleanProfile(profile) })
                activeProfileName = profile.name
                logger_module.info('[Global] Toggle ON for profile: ' .. profile.name)
            end
        else -- Momentary mode
            if activeProfileName and activeProfileName ~= profile.name then -- if a toggle is active, hide it
                sendToPlayerRenderer('TTO_HideHighlights', {})
                 activeProfileName = nil -- clear toggle if momentary for different profile is pressed
            end
            -- For momentary, ensure no other momentary is active from a different profile
            if momentaryActiveProfileName and momentaryActiveProfileName ~= profile.name then
                 sendToPlayerRenderer('TTO_HideHighlights', {})
            end

            sendToPlayerRenderer('TTO_ShowHighlights', { profile = cleanProfile(profile) })
            momentaryActiveProfileName = profile.name 
            -- activeProfileName = profile.name -- Do not set activeProfileName for momentary presses to allow toggles to persist
            logger_module.info('[Global] Momentary ON for profile: ' .. profile.name)
        end
    elseif eventType == "release" then
        if not profile.modeToggle and momentaryActiveProfileName == profile.name then
            sendToPlayerRenderer('TTO_HideHighlights', {})
            momentaryActiveProfileName = nil
            -- activeProfileName = nil -- Do not clear activeProfileName (toggle) on momentary release
            logger_module.info('[Global] Momentary OFF for profile: ' .. profile.name)
        end
    end
end

-- Handle profiles update from menu script
local function onUpdateProfiles(data)
    if data and data.profiles and type(data.profiles)== 'table' then
        storage_module.setProfiles(data.profiles)
        profiles = data.profiles
        logger_module.info('[Global] Profiles updated from menu event. Count: '..#profiles)
    else
        logger_module.warn('[Global] TTO_UpdateProfiles event missing valid profiles table')
    end
end

-- Handle appearance settings update from menu script
local function onUpdateAppearance(data)
    if data and data.appearance and type(data.appearance) == 'table' then
        storage_module.set('appearance', data.appearance)
        logger_module.info('[Global] Appearance settings updated from menu event.')
    else
        logger_module.warn('[Global] TTO_UpdateAppearance event missing valid appearance table')
    end
end

-- Handle performance settings update from menu script
local function onUpdatePerformance(data)
    if data and data.performance and type(data.performance) == 'table' then
        storage_module.set('performance', data.performance)
        logger_module.info('[Global] Performance settings updated from menu event.')
    else
        logger_module.warn('[Global] TTO_UpdatePerformance event missing valid performance table')
    end
end

-- Handle general settings update from menu script
local function onUpdateGeneral(data)
    if data and data.general and type(data.general) == 'table' then
        storage_module.set('general', data.general)
        generalSettings = data.general
        -- Update logger debug state if it changed
        if generalSettings.debug ~= nil then
            logger_module.init(generalSettings.debug)
            logger_module.info('[Global] General settings updated from menu event. Debug: ' .. tostring(generalSettings.debug))
        end
    else
        logger_module.warn('[Global] TTO_UpdateGeneral event missing valid general table')
    end
end

-- No map function needed if not used by active code
-- local function map(tbl, fn) return {} end

return {
    -- engineHandlers = {} -- NO onLoad/onSave for GLOBAL scripts
    eventHandlers = {
        TTO_GlobalKeyEvent = onGlobalKeyEvent,
        TTO_UpdateProfiles = onUpdateProfiles,
        TTO_UpdateAppearance = onUpdateAppearance,
        TTO_UpdatePerformance = onUpdatePerformance,
        TTO_UpdateGeneral = onUpdateGeneral
    }
}