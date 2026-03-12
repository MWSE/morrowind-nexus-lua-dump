mp = "scripts/MaxYari/MercyCAO/"

local gutils = require(mp .. "scripts/gutils")
local json = require(mp .. "libs/json")

local core = require("openmw.core")
local types = require("openmw.types")
local vfs = require('openmw.vfs')
local markup = require("openmw.markup")

DebugLevel = 1

if core.API_REVISION < 64 then return end

-- Parsing JSON behaviourtree -----
gutils.print("Global: Reading Behavior3 project", 1)
-- Read the behaviour tree JSON file exported from the editor---------------
local file = vfs.open(mp .. "OpenMW AI.b3")
if not file then error("Failed opening behaviour tree file.") end
-- Decode it
local b3projectJson = json.decode(file:read("*a"))
-- And close it
file:close()
----------------------------------------------------------------------------

-- Loading the blacklist yaml files from configs folder -----
local function loadBlacklists()
    local mergedBlacklist = {
        full_disable = { recordIds = {}, cellIds = {} },
        surrender_disable = { recordIds = {}, cellIds = {} }
    }

    -- Helper to merge list entries from a section
    local function mergeSection(source, target)
        if source.recordIds then
            for _, id in ipairs(source.recordIds) do
                table.insert(target.recordIds, id)
            end
        end
        if source.cellIds then
            for _, id in ipairs(source.cellIds) do
                table.insert(target.cellIds, id)
            end
        end
    end

    -- Collect all YAML files from configs folder
    for configPath in vfs.pathsWithPrefix(mp .. "configs/") do
        -- Check if it's a yaml file
        if configPath:match("%.yaml$") then
            local blacklistData = markup.loadYaml(configPath)
            if blacklistData then
                if blacklistData.full_disable then
                    mergeSection(blacklistData.full_disable, mergedBlacklist.full_disable)
                end
                if blacklistData.surrender_disable then
                    mergeSection(blacklistData.surrender_disable, mergedBlacklist.surrender_disable)
                end
            end
        end
    end

    -- Convert lists to maps for O(1) lookup performance
    local function listToMap(list)
        local map = {}
        for _, id in ipairs(list) do
            map[id] = true
        end
        return map
    end

    local processedBlacklist = {}
    for key, section in pairs(mergedBlacklist) do
        processedBlacklist[key] = {
            recordIdsMap = listToMap(section.recordIds),
            cellIdsMap = listToMap(section.cellIds)
        }
    end

    return processedBlacklist
end

blacklist = loadBlacklists()
-----------------------------------------------------------------------------


local pendingActors = {}

local function onUpdate() 
    -- Send one actor event per frame. Hopefully distributing the workload and removing the stutter.
    if #pendingActors > 0 then
        local actor = table.remove(pendingActors)
        actor:sendEvent("Mercy_StartupData",{
            b3projectJson = b3projectJson,
            blacklist = blacklist,
        })
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        HiImMercyActor = function(data)
            table.insert(pendingActors,data.source)
        end,
        dumpInventory = function(data)
            -- data.actor, data.position
            local actor = gutils.Actor:new(data.actorObject)
            local items = actor:getDumpableInventoryItems()
            for _, item in pairs(items) do
                item:teleport(data.actorObject.cell, data.position, { onGround = true })
                item.owner.factionId = nil
                item.owner.recordId = nil
                ::continue::
            end
        end,
        openTheDoor = function(data)
            local actor = gutils.Actor:new(data.actorObject)
            if actor:canOpenDoor(data.doorObject) then
                types.Door.activateDoor(data.doorObject, true)
            end
        end
    },
}
