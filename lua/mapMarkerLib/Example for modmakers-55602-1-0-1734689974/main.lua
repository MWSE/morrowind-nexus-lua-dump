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
        scale = 0.5, -- scale value for the texture
        -- by default, the marker texture points to the object with its upper left corner.
        -- This value shifts the texture. Negative values shift left, positive values shift right.
        -- The value is applied after scaling. If null, the value will be equal to -textureWidth / 2
        textureShiftX = -16,
        -- same as for the previous value, but negative values shift left, positive values shift right.
        -- If null, the value will be equal to textureHeight / 2
        textureShiftY = 16,
        color = {math.random(), math.random(), math.random()}, -- color of the marker and its text
        name = string.format("\"%s\" (priority: %d)", ref.baseObject.name, priority), -- first line of text on the tooltip
        description = string.format("I'm a creature, tracked by ref"), -- second line of text on the tooltip
        -- there may be multiple markers on the same object. The icon will be the one whose priority value is higher.
        -- Also affects the order of text in tooltip
        priority = priority,
        temporary = true, -- records with this parameter are not saved to game save files
    }

    -- creates a record. If unsuccessful, returns null. It can also be created by mapMarkerLib.addRecord(recordParams)
    local record = mapMarkerLib.record.new(recordParams)
    if not record then return end

    -- save the record to be able to remove all markers with it later
    records[record] = true

    ---@type markerLib.addLocalMarker.params
    local localMarkerParams = {
        record = record, -- the record that the marker will use
        trackedRef = ref, -- the reference that the marker will track. If the reference is deleted, the marker will be deleted. The marker will not be saved to game save files
        temporary = true, -- the marker will not be saved to game save files
        trackOffscreen = true, -- the marker will be displayed on the local map even if the object is offscreen
    }

    -- creates a marker. If unsuccessful, returns null. It can also be created by mapMarkerLib.addLocalMarker(localMarkerParams)
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
        name = string.format("\"%s\" (priority: %d)", object.name, priority), -- first line of text on the tooltip
        description = string.format("I'm an NPC with gold, tracked by object id"), -- second line of text on the tooltip
        priority = priority, -- priority value for the marker
        temporary = true, -- records with this parameter are not saved to game save files
    }

    -- creates a record. If unsuccessful, returns null. It can also be created by mapMarkerLib.addRecord(recordParams)
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

    -- creates a marker. If unsuccessful, returns null. It can also be created by mapMarkerLib.addLocalMarker(localMarkerParams)
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
        name = "Coordinates:", -- first line of text on the tooltip
        description = string.format("x: %d, y: %d", position.x, position.y), -- second line of text on the tooltip
        priority = priority, -- priority value for the marker
        temporary = true, -- records with this parameter are not saved to game save files
    }

    -- creates a record. If unsuccessful, returns null. It can also be created by mapMarkerLib.addRecord(recordParams)
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
    }

    -- creates a marker. If unsuccessful, returns null. It can also be created by mapMarkerLib.addLocalMarker(localMarkerParams)
    local localMarker = mapMarkerLib.localMarker.new(localMarkerParams)
    if not localMarker then return end

    -- if the cell is exterior, then create a marker for the world map
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
            temporary = true, -- the marker will not be saved to game save files
        }

        -- creates a marker. If unsuccessful, returns null. It can also be created by mapMarkerLib.addWorldMarker(worldMarkerParams)
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
    -- if the player presses the Y key and holds down the Shift key, then remove all markers
    if tes3.worldController.inputController:isShiftDown() then
        for record, _ in pairs(records) do
            record:remove()
        end
        -- the map menu usually updates automatically, but if the game is paused, it needs to be updated manually
        mapMarkerLib.updateLocalMarkers(true)
        mapMarkerLib.updateWorldMarkers(true)
        records = {}
        npcIdsWithMarker = {}
        refsWithMarker = {}
    end
end
event.register(tes3.event.keyDown, keyDownCallback, {filter = tes3.scanCode.y})