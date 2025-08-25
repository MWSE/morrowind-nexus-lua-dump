
-- This example shows how to create markers using proximityTool.

-- It adds markers for exit doors in interior cells. When you click on the marker field, the display range of HUD markers changes.

-- The descriptions in this example only concern the operation of proximityTool, without describing other parts of the example.


-- proximityTool supports lua annotations, the file describing them is stored in the /scripts/proximityTool/interop directory of the mod itself
require("scripts.simple-exit-detector.annotations")

local core = require("openmw.core")
local playerRef = require("openmw.self")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")


local function getScaledScreenSize()
    return ui.layers[ui.layers.indexOf("HUD")].size
end


local function onTeleported()
    local playerCell = playerRef.cell
    if not playerCell.isExterior and not playerCell:hasTag("QuasiExterior") then
        core.sendGlobalEvent("Simple-Exit-Detector:createMarkersForPlayerCell")
    end
end



local function createMarkers(data)
    if not I.proximityTool then return end

    ---@type proximityTool
    local proximityTool = I.proximityTool


    for _, info in pairs(data) do

        -- proximityTool provides a wrapper for HUDMarkers (https://www.nexusmods.com/morrowind/mods/57112)
        -- You can use proximityTool.addHUDM to create a HUDMarker

        -- Possible values for this parameter can be found in scripts\HUDMarkers\HUDM_p.lua HUDMarkers
        local hudmParam = {
            icon = "textures/simple-exit-detector/exitdoorIcon.dds",
            scale = 2 * getScaledScreenSize().y / 1080,
            raytracing = false,
            range = 40,
            opacity = 1,
            screenOffset = util.vector2(0, 0),
            boundingBoxCenter = true,
            offset = util.vector3(0, 0, 40),
            bonusSize = 10,
            color = {202/255, 165/255, 96/255},
        }



        ---@type proximityTool.hudm
        local hudmData = {
            modName = "simple-exit-detector", -- name of the mod that creates this HUDMarker. Required parameter
            params = hudmParam, -- HUDMarkers parameters
            version = 6, -- version of HUDMarkers this HUDMarker is compatible with. Must be >= 6
            objects = info.refs, -- List of GameObject[] to be tracked by the HUDMarker. Markers with this parameter are not saved in game save files
            -- objectIds = {"player"}, -- List of RecordId of objects to be tracked by the HUDMarker
            shortTerm = true, -- If true, the HUDMarker will be removed when one of the tracked objects is invalidated. Markers with this parameter are not saved in game save files
            -- hidden = false, -- If true, the HUDMarker will be hidden when created
            -- hideDead = true, -- If true, the HUDMarker will be hidden if the object is dead
            -- itemId = "gold_001", -- Do not show the marker if the object does not own this item. Objects with unresolved item list ignore this
            -- temporary = true, -- If true, the HUDMarker will not be saved in game save files. 
        }


        -- Creating a HUDMarker
        -- Returns HUDMarker ids, which are always unique
        -- Using the ids, you can later remove the HUDMarker via proximityTool.removeHUDM(hudmId)
        -- Or manage its visibility via proximityTool.setHUDMvisibility(hudmId, visible)
        local hudmId = proximityTool.addHUDM(hudmData)

        -- Updating HUDMarker.
        -- Creation does not require updating, but removal or changing visibility does
        -- proximityTool.updateHUDM(hudmId)

        -- Remove HUDMarker
        -- proximityTool.removeHUDM(hudmId)

        -- Manage HUDMarker visibility
        -- proximityTool.setHUDMvisibility(hudmId, visible)



        --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



        -- To create proximity markers, you need to create a record and a marker
        -- record stores information about visual representation of a marker
        -- marker stores information about tracked objects
        -- You can create one record via proximityTool.addRecord and use it for several markers
        -- Or you can write the record information directly into the marker
        -- If you create a record via proximityTool.addRecord, you can use the returned id
        -- both to create markers and to remove all markers with this record via proximityTool.removeRecord(id)

        -- !!!!!!The mod itself stores information about markers and saves it in game saves!!!!!!
        -- If you need to manage markers, use their ids
        -- Or create temporary markers with parameters temporary = true or shortTerm = true

        ---@type proximityTool.record
        local recordData = {
            name = info.name, -- marker name, which will be displayed in the interface
            -- Marker description, which will be displayed in the tooltip
            -- If you need multiple lines of description, you can assign an array of strings. Then the iconColor field must also be an array
            description = info.description,
            -- Path to the marker icon, which is displayed next to the name
            icon = "textures/simple-exit-detector/exitdoorIcon.dds",
            iconColor = {202/255, 165/255, 96/255}, -- icon color. Must be an array!
            iconRatio = 1, -- icon height to width ratio
            priority = 100, -- marker priority, markers with higher priority will be higher in the list
            proximity = 99999, -- distance at which the marker will be visible. In game units
            events = {
                MouseClick = "Simple-Exit-Detector:onClickCallback",
            },

            -- alpha = 1, -- marker transparency
            -- descriptionColor = {1, 1, 1}, -- marker description color. Can be an array of colors if description is an array. Like {{1, 1, 1},{1, 1, 1}}
            -- nameColor = {1, 1, 1}, -- marker name color
            -- temporary = true, -- if true, the marker will not be saved between sessions (in game save files)
            -- options = {
            --     hideDead = true, -- hide markers on dead creatures
                -- By default, the marker uses the positions of the first category whose objects are found.
                -- object > objects > objectId > objectIds > positions
                -- If you set this parameter to true, the marker will track all objects of all types together
                -- trackAllTypesTogether = false,
            -- }
        }

        -- Creating a marker record
        -- local markerRecordId = proximityTool.addRecord(recordData)

        -- If you created a record, you can use its id to create a marker by specifying its markerRecordId in the record field

        -- Remove all markers with this record and the record itself
        -- proximityTool.removeRecord(markerRecordId)

        -- Manage the visibility of markers with the record
        -- proximityTool.setVisibility(markerRecordId, nil, visible)


        ---@type proximityTool.marker
        local markerData = {
            record = recordData, -- record to be used for this marker. Can be created via proximityTool.addRecord or written directly into marker
            -- Marker group name. All markers with the same group name will be grouped. If this parameter is not set, markers will be in the default group
            -- If it starts with ~, the group name will not be displayed in the interface
            groupName = "~Closest exit:",
            objects = info.refs, -- List of GameObject[] to be tracked by the marker. Markers with this parameter are not saved in game save files
            -- object = playerRef, -- GameObject to be tracked by the marker. Markers with this parameter are not saved in game save files
            -- objectId = "player", -- RecordId of objects to be tracked by the marker
            -- objectIds = {"player"}, -- List of RecordId of objects to be tracked by the marker
            -- positions = { -- List of positions to be tracked by the marker
            --     {
            --         cell = {isExterior = playerRef.cell.isExterior, id = playerRef.cell.id},
            --         position = playerRef.position
            --     },
            -- },

            shortTerm = true, -- If true, the marker will be removed when the player changes location. Markers with this parameter are not saved in game save files
            userData = {
                hudmId = hudmId,
                shortRange = true,
            },

            -- temporary = true, -- If true, the marker will not be saved in game save files
            -- itemId = "gold_001" -- do not show the marker if the object does not own this item. Objects with unresolved item list ignore this
        }


        -- Creating a marker
        -- Returns marker ids.
        -- The first is always unique
        -- Using the ids, you can later remove the marker via proximityTool.removeMarker(markerId, markerGroupId)
        -- Or manage its visibility via proximityTool.setVisibility(markerId, markerGroupId, visible)
        -- If you created a record, you can use its id to remove all markers with this record
        -- Or manage their visibility via proximityTool.setVisibility(markerRecordId, nil, visible)
        local markerId, markerGroupId = proximityTool.addMarker(markerData)

        -- Some operations require updating markers
        -- For example, changing visibility and removal.
        -- Creation usually does not require updating
        -- proximityTool.update()

        -- Remove marker
        -- proximityTool.removeMarker(markerId, markerGroupId)

        -- Manage marker visibility
        -- proximityTool.setVisibility(markerId, markerGroupId, visible)

    end


    -- As a bonus, proximityTool also provides a real-time timer function
    -- local cancel = proximityTool.newRealTimer(duration, function() end)
    -- cancel() -- cancel the timer if it is no longer needed
end


-- Callback for the event triggered when the marker field is clicked
---@param data proximityTool.event.callbackParams
local function onClickCallback(data)
    if data.eventArgument.button ~= 1 then return end -- 1 - left mouse button
    if not data.data.userData or not data.data.userData.hudmId then return end

    ---@type proximityTool
    local proximityTool = I.proximityTool

    ---@type table
    local userData = data.data.userData
    local hudmId = userData.hudmId

    ---@type proximityTool.hudm?
    local hudmData = proximityTool.getHUDMdata(hudmId) -- returns a copy of the data used to create this marker
    if not hudmData then return end

    local shortRange = not userData.shortRange
    hudmData.params.range = shortRange and 40 or 999

    -- remove the old marker
    proximityTool.removeHUDM(hudmId)

    -- create a new marker based on the modified data
    hudmId = proximityTool.addHUDM(hudmData)
    -- assign new userData with the new id, so you can interact with the new marker later
    proximityTool.setUserData(data.id, data.groupId, {hudmId = hudmId, shortRange = shortRange})

    -- after removing markers (like proximityTool.removeHUDM), always call update to refresh the UI
    proximityTool.updateHUDM()
end



return {
    engineHandlers = {
        onTeleported = function ()
            async:newUnsavableSimulationTimer(0.5, function () -- delay to allow player cell info to update
                onTeleported()
            end)
        end,

        onLoad = function ()
            async:newUnsavableSimulationTimer(0.5, function ()
                onTeleported()
            end)
        end,
    },
    eventHandlers = {
        ["Simple-Exit-Detector:createMarkers"] = createMarkers,
        ["Simple-Exit-Detector:onClickCallback"] = onClickCallback,
    },
}