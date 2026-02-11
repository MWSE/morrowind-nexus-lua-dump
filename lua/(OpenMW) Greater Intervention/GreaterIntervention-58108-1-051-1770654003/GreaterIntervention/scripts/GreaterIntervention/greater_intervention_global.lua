local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')

local markers = { templemarker = {}, divinemarker = {} }
local TARGET_IDS = { templemarker = true, divinemarker = true }

local SPELL_ALMSIVI = "almsivi intervention greater"
local SPELL_DIVINE = "divine intervention greater"

local globals = world.mwscript.getGlobalVariables()

-- Function to set MWScript Globals depending on whether player has Greater Intervention spells or not.
local function updateInterventionGlobals()
    -- Ensure Globals are present.
    if not globals.PCHasGreaterAlmsiviIntervention
    or not globals.PCHasGreaterDivineIntervention
    or not globals.GreaterAlmsiviIntAddTopicTrigger
    or not globals.GreaterDivineIntAddTopicTrigger then
        print("[Greater Intervention]: Global Variables missing. Ensure GreaterIntervention.omwaddon is active.")
        return
    end

    -- Reset globals before checking.
    globals.PCHasGreaterAlmsiviIntervention = 0
    globals.PCHasGreaterDivineIntervention = 0
    globals.GreaterAlmsiviIntAddTopicTrigger = -1
    globals.GreaterDivineIntAddTopicTrigger = -1

    -- Manually iterate through the spells list.
    local playerSpells = types.Actor.spells(world.players[1])
    for _, spell in ipairs(playerSpells) do
        local id = spell.id:lower()
        if id == SPELL_ALMSIVI then globals.PCHasGreaterAlmsiviIntervention = 1
        elseif id == SPELL_DIVINE then globals.PCHasGreaterDivineIntervention = 1 end
    end
    
    -- Set add topic triggers based on whether player has spells or not.
    if globals.PCHasGreaterAlmsiviIntervention == 0 then globals.GreaterAlmsiviIntAddTopicTrigger = 1 end
    if globals.PCHasGreaterDivineIntervention == 0 then globals.GreaterDivineIntAddTopicTrigger = 1 end
    
    -- Comment before ship
    --print(globals.PCHasGreaterAlmsiviIntervention .. globals.PCHasGreaterDivineIntervention .. globals.GreaterAlmsiviIntAddTopicTrigger .. globals.GreaterDivineIntAddTopicTrigger)
end

return {
    engineHandlers = {
        -- This is run for every static object that is loaded in the world.
        onObjectActive = function(obj)
            -- If the current object is a marker
            local id = obj.recordId:lower()
            if TARGET_IDS[id] then
                -- Only add marker if player has corresponding spell.
                --if id == "templemarker" and globals.PCHasGreaterAlmsiviIntervention == 0 then return end
                --if id == "divinemarker" and globals.PCHasGreaterDivineIntervention == 0 then return end

                -- Ensure the current marker has not already been found.
                local list = markers[id]
                for _, pos in ipairs(list) do
                    if pos.x == obj.position.x and pos.y == obj.position.y then return end
                end

                -- Get the location name. If an external cell, use the cell region or region name. Default to "Wilderness".
                local displayName = obj.cell.name
                if not displayName or displayName == "" then
                    displayName = (obj.cell.region and obj.cell.region.name) or "Wilderness"
                end

                -- Insert marker into corresponding list.
                table.insert(list, {
                    x = obj.position.x, y = obj.position.y, z = obj.position.z,
                    cell = obj.cell.name, label = displayName
                })
                
                -- Notification of new marker discovery.
                print("[Greater Intervention]: Found " .. id .. " in " .. displayName)
                world.players[1]:sendEvent('receiveNewDiscovery', displayName)
            end
        end,

        -- First load of script. Set Global Variables used by MWScripts.
        onInit =
            function(initData)
                updateInterventionGlobals()
                print("[GreaterIntervention]: Script initialised.")
        end,
        
        -- Save marker lists upon game save.
        onSave = function() return { markers = markers } end,

        -- Retrieve marker lists upon script load.
        onLoad =
            function(data)
                if data and data.markers then
                    markers = data.markers
                end
            -- Set Global Variables used by MWScripts
            updateInterventionGlobals()
            print("[GreaterIntervention]: Script loaded.")
        end
    },
    eventHandlers = {
        -- This function provides the Player script with Teleport data from the
        -- marker lists by sending the receiveTeleportData event.
        requestTeleportData = function(data)
            local requestedMarkers = markers[data.type] or {}
            world.players[1]:sendEvent('receiveTeleportData', requestedMarkers)
        end,
        -- This function provides the Player script with Marker data from the
        -- marker lists by sending the receiveMarkerData event.
        requestMarkerData = function(data)
            local requestedMarkers = markers[data.type] or {}
            world.players[1]:sendEvent('receiveMarkerData', {markerList = requestedMarkers, markerType = data.type})
        end,
        -- Same as above, but for MWE Player script.
        requestMarkerDataMWE = function(data)
            local requestedMarkers = markers[data.type] or {}
            world.players[1]:sendEvent('receiveMarkerDataMWE', {markerList = requestedMarkers, markerType = data.type})
        end,
        -- This function teleports the player to the location selected from the menu
        executeTeleport = function(data)
            local destCell = world.getCellByName(data.cell)
            local pos = util.vector3(data.x, data.y, data.z)
            world.players[1]:teleport(destCell, pos)
        end
    }
}
