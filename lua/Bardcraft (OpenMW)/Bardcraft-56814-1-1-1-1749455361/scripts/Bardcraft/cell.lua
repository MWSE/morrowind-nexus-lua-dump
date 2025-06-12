local types = require('openmw.types')

local Song = require('scripts.Bardcraft.util.song').Song
local Data = require('scripts.Bardcraft.data')

local C = {}

C.StreetType = {
    Town = 1,
    City = 2,
    Metropolis = 3,
}

function C.getPublican(cell)
    if not cell then return nil end
    if cell.isExterior then return nil end
    local npcs = cell:getAll(types.NPC)

    -- Get venue record for this cell, if any
    local publicanId = nil
    if Data.Venues.tavern and Data.Venues.tavern[string.lower(cell.name)] then
        publicanId = string.lower(Data.Venues.tavern[string.lower(cell.name)])
    end

    for _, npc in ipairs(npcs) do
        if not types.Actor.isDead(npc) then
            local record = types.NPC.record(npc)
            if record then
                if Data.PublicanClasses[record.class] then
                    return npc
                end
                if publicanId and string.lower(record.id) == publicanId then
                    return npc
                end
            end
        end
    end

    return nil
end

function C.cellHasPublican(cell)
    return C.getPublican(cell) ~= nil
end

function C.canPerformHere(cell, type)
    if type == Song.PerformanceType.Tavern then
        if C.cellHasPublican(cell) then
            return true
        end
        return nil
    elseif type == Song.PerformanceType.Street then
        if not cell.isExterior then return nil end
        -- Check if the cell is in the list of street performance locations
        local streetData = Data.Venues.street
        if not streetData then return nil end
        for _, venue in ipairs(streetData.metropolises) do
            if string.find(cell.name, venue, 1, true) then
                return true, venue, C.StreetType.Metropolis
            end
        end
        for _, venue in ipairs(streetData.cities) do
            if string.find(cell.name, venue, 1, true) then
                return true, venue, C.StreetType.City
            end
        end
        for _, venue in ipairs(streetData.towns) do
            if string.find(cell.name, venue, 1, true) then
                return true, venue, C.StreetType.Town
            end
        end
        return nil
    elseif (type == Song.PerformanceType.Practice or type == Song.PerformanceType.Ambient) then
        if not C.canPerformHere(cell, Song.PerformanceType.Tavern) then
            return type
        else
            return nil
        end
    elseif type == Song.PerformanceType.Perform then
        if C.canPerformHere(cell, Song.PerformanceType.Tavern) then
            return Song.PerformanceType.Tavern
        end
        local streetResult, streetName, streetType = C.canPerformHere(cell, Song.PerformanceType.Street)
        if streetResult then
            return Song.PerformanceType.Street, streetName, streetType
        end
        return nil
    end
end

return C