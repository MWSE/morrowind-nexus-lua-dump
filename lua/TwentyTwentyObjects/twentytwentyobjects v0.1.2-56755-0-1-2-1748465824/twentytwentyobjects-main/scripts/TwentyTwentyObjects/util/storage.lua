-- storage.lua: Storage utilities for Twenty Twenty Objects Mod
-- Handles persistent settings and profile management

local M = {}

local modConfig = nil
local isInitialized = false -- Tracks if modConfig has been successfully fetched
local engine_storage_ref = nil -- To store the require('openmw.storage') result

-- Internal function to get (and initialize if needed) the modConfig
-- This is the ONLY place require('openmw.storage') and globalSection() should be called.
local function getModConfig()
    if isInitialized and modConfig then
        return modConfig
    end

    -- Try to get the engine storage module instance
    if not engine_storage_ref then
        local status, result = pcall(require, 'openmw.storage')
        if not status or not result then
            print("[TTO Storage ERROR] Failed to require('openmw.storage'): " .. tostring(result))
            return nil -- Cannot proceed
        end
        engine_storage_ref = result
    end

    -- Try to get the global section
    local config_status, config_result = pcall(engine_storage_ref.globalSection, 'TwentyTwentyObjects')
    if not config_status or not config_result then
        print("[TTO Storage ERROR] Failed to get globalSection 'TwentyTwentyObjects': " .. tostring(config_result))
        isInitialized = false -- Mark as failed init attempt to avoid retrying constantly if it's a persistent issue
        modConfig = nil
        return nil -- Cannot proceed
    end
    
    modConfig = config_result
    isInitialized = true
    print("[TTO Storage INFO] Successfully initialized modConfig for 'TwentyTwentyObjects'.")
    return modConfig
end

-- Get a setting with optional default value
function M.get(key, default_value)
    local currentModConfig = getModConfig()
    if not currentModConfig then return default_value end

    local value = currentModConfig:get(key)
    if value == nil then
        return default_value
    end
    return value
end

-- Set a setting value
function M.set(key, value)
    local currentModConfig = getModConfig()
    if not currentModConfig then return end -- Silently fail if storage isn't up
    currentModConfig:set(key, value)
end

-- Subscribe to storage changes
function M.subscribe(callback)
    local currentModConfig = getModConfig()
    if not currentModConfig then return end
    currentModConfig:subscribe(callback)
end

-- Get all profiles
function M.getProfiles()
    local currentModConfig = getModConfig()
    if not currentModConfig then return {} end

    local profilesData = currentModConfig:get('profiles')
    -- OpenMW storage API returns nil or a valid table-like userdata object
    -- Just like PCP, we don't need to check the type - if it's not nil, it's valid
    if profilesData ~= nil then
        return profilesData
    else
        print('[TTO Storage INFO] Profiles key not found or nil. Returning empty table.')
        -- Do NOT attempt to write back from here if called from a non-Global context.
        -- Initialization/healing of this key is the Global script's responsibility.
        return {}
    end
end

-- Check if profiles exist
function M.hasProfiles()
    local currentModConfig = getModConfig()
    if not currentModConfig then return false end -- If storage isn't up, assume no profiles
    
    local profiles = M.getProfiles() 
    return #profiles > 0
end

-- Set all profiles
function M.setProfiles(profiles)
    local currentModConfig = getModConfig()
    if not currentModConfig then return end
    currentModConfig:set('profiles', profiles)
end

-- Initialize with default profiles if none exist
function M.initializeDefaults()
    local currentModConfig = getModConfig() -- Call it to ensure it tries to init
    if not currentModConfig then 
        print("[TTO Storage WARN] Cannot initialize defaults, storage not ready.")
        return true -- Act as if done, to not block, but logged failure
    end

    -- Check if profiles key exists at all
    local profilesData = currentModConfig:get('profiles')
    if profilesData == nil then 
        print("[TTO Storage INFO] initializeDefaults: No profiles key found, initializing with empty profile list.")
        -- Initialize with empty array - OpenMW storage needs this initial set
        currentModConfig:set('profiles', {})
        return true
    end
    return false
end

return M