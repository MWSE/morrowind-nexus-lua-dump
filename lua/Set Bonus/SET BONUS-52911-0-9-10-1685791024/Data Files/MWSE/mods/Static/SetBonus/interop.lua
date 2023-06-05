-- Import required modules
local log = require("Static.logger")
local config = require("Static.SetBonus.config")
local lfs = require('lfs')
-- Define the interop table to contain the module's functions
local interop = {}
-- 'registerSet' function: registers a set in the config
-- The function asserts the validity of input set data before proceeding with registration
---@param setData table responsible for registering a new set with its items into the system
function interop.registerSet(setData)
    log:trace("registerSet: Entry point. setData: %s", setData)
    -- Validating the set data
    assert(type(setData) == "table", "Error: set data did not return a table")
    assert(type(setData.name) == "string", "Error: set data has incorrect structure")
    assert(type(setData.items) == "table", "Error: set data has incorrect structure")
    -- Standardize set name to lowercase for consistency
    setData.name = setData.name:lower()
    -- Loop over each item in the set, validate the item, convert to lowercase, and register in the 'setLinks' table
    for i, item in ipairs(setData.items) do
        assert(type(item) == "string", "Error: set contains non-string item")
        setData.items[i] = item:lower()
        -- If item already linked to a set, add this set to the list. If not, create a new list for this item
        if not config.setLinks[setData.items[i]] then
            config.setLinks[setData.items[i]] = {} -- Initialize a new table for this item
        end
        -- Add the current set to the list of sets that this item belongs to
        config.setLinks[setData.items[i]][setData.name] = true -- Link the item to the set
    end
    -- Register set in the 'sets' table
    config.sets[setData.name] = setData
    -- Add set to an array-like structure for additional functionality
    table.insert(config.setsArray, setData)
    log:debug("registerSet: Set registered successfully. setData: %s", setData)
    log:trace("registerSet: Exit point")
end
-- 'registerSetLink' function: registers a set link in the configuration
-- The function validates the input set link data before registration
---@param setLinkData table responsible for creating a link between an already registered item and set
function interop.registerSetLink(setLinkData)
    log:trace("registerSetLink: Entry point. setLinkData: %s", setLinkData)
    -- Validate set link data
    assert(type(setLinkData.item) == "string", "Error: setLink data has incorrect structure")
    assert(type(setLinkData.set) == "string", "Error: setLink data has incorrect structure")
    -- Standardize item ID and set name to lowercase for consistency
    setLinkData.item = setLinkData.item:lower()
    setLinkData.set = setLinkData.set:lower()
    -- If this item hasn't been added to config.setLinks yet, add it as a new table
    if not config.setLinks[setLinkData.item] then
        config.setLinks[setLinkData.item] = {}
    end
    -- Add the current set to the list of sets that this item belongs to
    config.setLinks[setLinkData.item][setLinkData.set] = true
    log:debug("registerSetLink: Set link registered successfully. setLinkData: %s", setLinkData)
    log:trace("registerSetLink: Exit point")
end
-- 'initFile' function: registers a defined Lua file as sets
-- The function scans the files and registers each set in the file
---@param filePath string The path to the file to initialize
function interop.initFile(filePath)
    log:trace("initFile: Entry point. filePath: %s", filePath)
    for file in lfs.dir(filePath) do
        if file:match("(.+)%.lua$") then
            log:debug("initFile: Loading Lua file. file: %s", file)
            local successFile, set = dofile(filePath)
            if successFile then
                interop.registerSet(set)
            else
                log:error("Error loading set file: %s. Error: %s", filePath, set)
            end
        end
    end
    log:trace("initFile: Exit point")
end
-- 'initAll' function: initializes and registers all sets in a specified directory path
-- This function iterates over each Lua file in the directory, loads it, and registers it as a set
---@param pathDir string The path to the directory containing the files to initialize
function interop.initAll(pathDir)
    log:trace("initAll: Entry point. pathDir: %s", pathDir)
    for file in lfs.dir(pathDir) do
        if file:match("(.+)%.lua$") then
            log:debug("initAll: Loading Lua file. file: %s", file)
            local modulePath = pathDir .. "/" .. file
            local successScan, set = pcall(dofile, modulePath)
            if successScan then
                interop.registerSet(set)
            else
                log:error("Error loading set file: %s. Error: %s", modulePath, set)
            end
        end
    end
    log:trace("initAll: Exit point")
end
-- Return the interop module
return interop