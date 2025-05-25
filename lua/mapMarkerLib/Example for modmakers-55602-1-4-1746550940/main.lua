-- This example shows how to use the mapMarkerLib v1.4.0
-- This example creates markers for the local map:
-- For all NPCs that have gold in their inventory. Based on their object id.
-- For all creatures. Based on their tes3reference.
-- For all doors. Based on their coordinates.
-- And markers for the world map based on door coordinates.
-- All markers created in this example are not saved to game saves.
-- By pressing Shift+Y, all markers will be removed.
-- The library supports both OOP and functional programming styles, but this example is in the OOP style

-- The example has some issues. Some objects are not tracked because they are loaded before the library is initialized.
-- The library is initializing after the player is created.

local mapMarkerLib = include("diject.mapMarkerLib.interop")


-- a hash table for marker records.
-- The record stores texture, color, and tooltip text data for a marker.
-- There can be multiple markers with one record.
-- When a record is deleted, all of its markers are deleted.
-- A record is not saved if there are no markers that use it
---@type table<markerLib.recordOOP, boolean>
local records = {}

-- a hash table to prevent creation of multiple markers for a single reference.
-- But it not tracking if the reference is deleted
local refsWithMarker = {}

--- Creates a marker for a creature, by tes3reference
---@param ref tes3reference
local function createMarkerForCreature(ref)
    -- if a marker for this reference already exists, then exit
    if refsWithMarker[ref] then return end
    refsWithMarker[ref] = true

    local priority = math.random(0, 100)

    -- each marker needs a record to store texture and text data. For one record there can be several markers of different types
    ---@type markerLib.markerRecord
    local recordParams = {
        path = "vfx_conj_flare.dds", -- path to the marker texture relative to the Data Files\Textures directory
        pathAbove = "vfx_conj_flare02.dds", -- path to the marker texture when the object is above the player. Can be nil
        pathBelow = "vfx_conj_flare02.dds", -- path to the marker texture when the object is below the player. Can be nil
        scale = 0.5, -- if positive, the value is a scale value for the marker texture.
        -- If negative, the value is a height for the marker image in game map coordinates
        textureShiftX = -16, -- by default, the marker texture points to the object with its upper left corner.
        -- This value shifts the texture. Negative values shift left, positive values shift right.
        -- The value is applied after scaling. If nil, the value will be equal to -textureWidth / 2
        textureShiftY = 16, -- same as for the previous value, but negative values shift left, positive values shift right.
        -- If nil, the value will be equal to textureHeight / 2
        scaleTexture = nil, -- if true, the marker image will scale in proportion to map zoom. Applicable only to markers on the world map
        color = {math.random(), math.random(), math.random()}, -- color of the marker and its text
        name = string.format("\"%s\" (priority: %d)", ref.baseObject.name, priority),
        -- *name* and *description* are used to create a tooltip for the marker.
        -- *name* is the first line of text in the tooltip.
        -- *description* is the secornd and all other lines of text in the tooltip.
        -- You can use #objectName# to get the name of the object that the marker is tracking.
        -- You can use #itemName# to get the name of the item that the marker is tracking.
        nameColor = {1, 1, 1}, -- color of the name text
        description = {string.format("I'm a creature, tracked by ref"), "Click me",""}, -- the secornd and all other lines of text in the tooltip.
        -- Can be or an array of strings, or a string.
        -- If it is an array of strings, then each string will be displayed on a separate line.
        -- Empty strings will be ignored in the tooltip.
        -- You can use #objectName# to get the name of the object that the marker is tracking.
        -- You can use #itemName# to get the name of the item that the marker is tracking.
        descriptionColor = {1, 0.5, 1}, -- color of the description text
        priority = priority, -- there may be multiple markers on the same object. The icon will be the one whose priority value is higher.
        -- Also affects the order of text in tooltip
        alpha = math.random(), -- alpha value for the marker. 0 - fully transparent, 1 - fully opaque
        userData = {showHP = true, ref = ref}, -- user data that can be used to store any data.
        -- the data should be or serializable or the marker should be temporary.
        -- You can use this data in the events of the library.
        temporary = true, -- records with this parameter are not saved to game save files
        hide = true, -- if true, the marker will be hidden. The marker will not be displayed on the map and in the tooltip until this parameter is set to false.
        onClickCallback = function (eventData)
            -- This function is called when the marker is clicked.
            -- You can use this function to do something when the marker is clicked.
            -- Not serializable! Not saved to game save files. Should be updated every time the game is loaded and the mod is initialized
            ---@type markerLib.markerRecord
            local record = eventData.record -- this record
            local topRecord = eventData.topRecord -- Record with a higher priority
            ---@type tes3uiElement
            local element = eventData.marker
            ---@type markerLib.markerContainer?
            local markerContainer = eventData.data

            print(string.format("Marker \"%s\" was clicked", record.id))

            tes3.messageBox{message = "The marker was clicked"}
        end
    }

    -- creates a record. If unsuccessful, returns nil. It can also be created by mapMarkerLib.addRecord(recordParams)
    local record = mapMarkerLib.record.new(recordParams)
    if not record then return end

    local recordId = record:getId() -- You can use this to get the id of the record. It can be used to get the record later

    record = mapMarkerLib.record.get(recordId) -- get the record by id
    if not record then return end

    record:hide(false) -- show the marker again. (We hide it before in the recordParams)
    record:getData().hide = false -- or you can use this to show the marker again. (We hide it before in the recordParams)

    -- save the record to be able to remove all markers with it later
    records[record] = true

    ---@type markerLib.addLocalMarker.params
    local localMarkerParams = {
        record = record, -- the record that the marker will use
        trackedRef = ref, -- the reference that the marker will track. If the reference is deleted, the marker will be deleted. The marker will not be saved to game save files
        temporary = true, -- the marker will not be saved to game save files
        trackOffscreen = true, -- the marker will be displayed on the local map even if the object is offscreen
        shortTerm = true, -- the marker will be removed if the player's cell changes from interior to interior, exterior to interior, or interior to exterior
    }

    -- creates a marker. If unsuccessful, returns nil. It can also be created by mapMarkerLib.addLocalMarker(localMarkerParams)
    local localMarker = mapMarkerLib.localMarker.new(localMarkerParams)
    if not localMarker then return end
end


-- a hash table to prevent creation of multiple markers for a single object id
local npcIdsWithMarker = {}

--- Creates a marker for an NPC with gold in their inventory, by object id
---@param object tes3npc
local function createMarkerForNPCs(object)
    local objectId = object.id:lower()

    -- if a marker for this object id already exists, then exit
    if npcIdsWithMarker[objectId] then return end
    npcIdsWithMarker[objectId] = true

    local priority = math.random(0, 100)

    -- for a little more info about the parameters, see 39 line
    -- each marker needs a record to store texture and text data. For one record there can be several markers of different types
    ---@type markerLib.markerRecord
    local recordParams = {
        path = "vfx_alpha_spark02.dds", -- path to the marker texture relative to the Data Files\Textures directory
        pathAbove = "vfx_alt_star02.dds", -- path to the marker texture when the object is above the player
        pathBelow = "vfx_alt_star02.dds", -- path to the marker texture when the object is below the player
        scale = 0.25, -- scale value for the texture
        textureShiftX = -16, -- texture shift value for the x axis
        textureShiftY = 16, -- texture shift value for the y axis
        color = {math.random(), math.random(), math.random()}, -- color of the marker and its text
        name = string.format("\"%s\" (priority: %d)", object.name, priority), -- first line of text in the tooltip
        description = string.format("I'm an NPC with gold, tracked by object id"), -- second line of text in the tooltip
        priority = priority, -- priority value for the marker
        temporary = true, -- records with this parameter are not saved to game save files
    }

    -- creates a record. If unsuccessful, returns nil. It can also be created by mapMarkerLib.addRecord(recordParams)
    local record = mapMarkerLib.record.new(recordParams)
    if not record then return end

    -- save the record to be able to remove all markers with it later
    records[record] = true

    ---@type markerLib.addLocalMarker.params
    local localMarkerParams = {
        record = record, -- the record that the marker will use
        objectId = objectId, -- the object id that the marker will track
        itemId = "gold_001", -- the item id that if found in the object's inventory, the marker will be displayed
        temporary = true, -- the marker will not be saved to game save files
        trackOffscreen = true, -- the marker will be displayed on the local map even if the object is offscreen
    }

    -- creates a marker. If unsuccessful, returns nil. It can also be created by mapMarkerLib.addLocalMarker(localMarkerParams)
    local localMarker = mapMarkerLib.localMarker.new(localMarkerParams)
    if not localMarker then return end
end

-- a hash table to prevent creation of multiple markers for a single position
local positionsHashTable = {}

--- Creates a marker by coordinates
---@param cell tes3cell
---@param position tes3vector3
local function createMarkerForPosition(cell, position)
    local priority = math.random(0, 100)

    -- for a little more info about the parameters, see 39 line
    -- each marker needs a record to store texture and text data. For one record there can be several markers of different types
    ---@type markerLib.markerRecord
    local recordParams = {
        path = "vfx_whitestar02.dds", -- path to the marker texture relative to the Data Files\Textures directory
        scale = 0.5, -- scale value for the texture
        textureShiftX = -16, -- texture shift value for the x axis
        textureShiftY = 16, -- texture shift value for the y axis
        color = {math.random(), math.random(), math.random()}, -- color of the marker and its text
        name = "Coordinates:", -- first line of text in the tooltip
        description = string.format("x: %d, y: %d", position.x, position.y), -- second line of text in the tooltip
        priority = priority, -- priority value for the marker
        temporary = true, -- records with this parameter are not saved to game save files
        scaleTexture = true,
    }

    -- creates a record. If unsuccessful, returns nil. It can also be created by mapMarkerLib.addRecord(recordParams)
    local record = mapMarkerLib.record.new(recordParams)
    if not record then return end

    -- save the record to be able to remove all markers with it later
    records[record] = true

    ---@type markerLib.addLocalMarker.params
    local localMarkerParams = {
        record = record, -- the record that the marker will use
        position = position, -- the position that the marker will track
        cell = cell, -- the cell where the position is located
        shortTerm = true, -- the marker will be removed if the player's cell changes from interior to interior, exterior to interior, or interior to exterior
        temporary = true, -- the marker will not be saved to game save files
        group = false, -- if false, the marker will not be grouped with other markers. Only for positional markers.
        insertBefore = true, -- if true, the marker will be inserted before other markers. Only for positional markers. Markers with this flag cannot be grouped with other markers
    }

    -- creates a marker. If unsuccessful, returns nil. It can also be created by mapMarkerLib.addLocalMarker(localMarkerParams)
    local localMarker = mapMarkerLib.localMarker.new(localMarkerParams)
    if not localMarker then return end

    -- if the cell is exterior, also create a marker for the world map.
    if not cell.isInterior then
        -- if a marker for this position already exists, then exit
        local hash = string.format("%s_%d_%d", cell.id, position.x, position.y)
        if positionsHashTable[hash] then return end
        positionsHashTable[hash] = true

        ---@type markerLib.addWorldMarker.params
        local worldMarkerParams = {
            record = record, -- the record that the marker will use
            x = position.x, -- x coordinate in world coordinates
            y = position.y, -- y coordinate in world coordinates
            scaleTexture = true, -- if true, the marker will scale in proportion to map zoom. Suitable for UI Expansion
            temporary = true, -- the marker will not be saved to game save files
        }

        -- creates a marker. If unsuccessful, returns nil. It can also be created by mapMarkerLib.addWorldMarker(worldMarkerParams)
        local worldMarker = mapMarkerLib.worldMarker.new(worldMarkerParams)
    end
end

--- @param e referenceActivatedEventData
local function referenceActivatedCallback(e)
    local objectType = e.reference.baseObject.objectType
    local ref = e.reference

    -- if the reference is the player, then exit because the library is initialized after the player is created
    if ref.baseObject.id == "player" then
        return
    end

    -- if the reference is a creature, then create a marker by object id for it
    -- if the reference is an NPC, then create a marker by reference for it
    -- if the reference is a door, then create a marker by coordinates for it
    if objectType == tes3.objectType.npc then
        createMarkerForNPCs(ref.baseObject)
    elseif objectType == tes3.objectType.creature then
        createMarkerForCreature(ref)
    elseif objectType == tes3.objectType.door then
        createMarkerForPosition(ref.cell, ref.position)
    end

end

event.register(tes3.event.referenceActivated, referenceActivatedCallback)

--- @param e keyDownEventData
local function keyDownCallback(e)
    -- removes all markers if the player presses Shift+Y.
    if tes3.worldController.inputController:isShiftDown() then
        for record, _ in pairs(records) do
            record:remove()
        end
        -- the map menu usually updates automatically, but if you want to update it immediately, you can call this functions
        mapMarkerLib.updateLocalMarkers(true)
        mapMarkerLib.updateWorldMarkers(true)
        records = {}
        npcIdsWithMarker = {}
        refsWithMarker = {}
    end
end
event.register(tes3.event.keyDown, keyDownCallback, {filter = tes3.scanCode.y})


-- The lib contains several events that you can use to track initialization, deletion, and other events.

event.register(mapMarkerLib.event.initialized, function()
    -- The library is initialized. You can use it now.
    print("mapMarkerLib is initialized")
end)

event.register(mapMarkerLib.event.recordRemoved, function(e)
    -- The record is removed
    ---@type markerLib.markerRecord
    local data = e.data
    print(string.format("mapMarkerLib record deleted, id %s", e.id))
end--[[, {filter = recordId}]])

event.register(mapMarkerLib.event.markerRemoved, function(e)
    -- The marker is removed
    ---@type markerLib.markerData
    local data = e.data
    print(string.format("mapMarkerLib marker deleted, id %s, cellId %s", e.id, e.cellId))
end--[[, {filter = id}]])

event.register(mapMarkerLib.event.tooltipPreRecordRegistered, function(e)
    -- This event is triggered when the record is registered for the tooltip
    -- You can use this event to change the tooltip text or color
    ---@type markerLib.markerRecord
    local record = e.record
    ---@type tes3uiElement
    local tooltip = e.element

    if record.userData and record.userData.showHP then
        -- if the record has user data, then use it to change the tooltip text
        local ref = record.userData.ref
        local hp = ref.mobile.health.current
        local maxHp = ref.mobile.health.base
        record.description[3] = string.format("HP: %d/%d", hp, maxHp)
    end

    print(string.format("mapMarkerLib record %s was registered for tooltip", record.id))
end--[[, {filter = recordId}]])

event.register(mapMarkerLib.event.tooltipCreated, function(e)
    -- This event is triggered when the tooltip was created
    ---@type tes3uiElement
    local tooltip = e.element
    ---@type markerLib.markerRecord[]
    local records = e.records
    print(string.format("mapMarkerLib tooltip created"))
end)