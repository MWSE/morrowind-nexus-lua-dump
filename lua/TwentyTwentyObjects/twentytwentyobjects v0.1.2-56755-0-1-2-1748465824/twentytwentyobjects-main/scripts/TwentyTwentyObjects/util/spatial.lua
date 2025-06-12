-- spatial.lua: Spatial optimization utilities for efficient object queries
-- Implements hierarchical spatial hashing and frustum culling

local util = require('openmw.util')
local camera = require('openmw.camera')

local M = {}

-- Spatial hash implementation with multiple cell sizes
local SpatialHash = {}
SpatialHash.__index = SpatialHash

function SpatialHash:new(cellSizes)
    local self = setmetatable({}, SpatialHash)
    self.cellSizes = cellSizes or {64, 128, 256, 512, 1024, 2048}
    self.grids = {}
    
    -- Initialize grids for each cell size
    for _, size in ipairs(self.cellSizes) do
        self.grids[size] = {}
    end
    
    return self
end

-- Hash a position to grid coordinates
function SpatialHash:hashPosition(pos, cellSize)
    return {
        x = math.floor(pos.x / cellSize),
        y = math.floor(pos.y / cellSize),
        z = math.floor(pos.z / cellSize)
    }
end

-- Get hash key string
function SpatialHash:getKey(hash)
    return string.format("%d,%d,%d", hash.x, hash.y, hash.z)
end

-- Insert object into appropriate grids
function SpatialHash:insert(object, position)
    local objData = {
        object = object,
        position = position,
        lastSeen = 0  -- Frame counter for temporal coherence
    }
    
    -- Insert into smallest appropriate cell size
    for _, cellSize in ipairs(self.cellSizes) do
        local hash = self:hashPosition(position, cellSize)
        local key = self:getKey(hash)
        
        if not self.grids[cellSize][key] then
            self.grids[cellSize][key] = {}
        end
        
        table.insert(self.grids[cellSize][key], objData)
        break  -- Only insert into one grid level
    end
end

-- Query objects within radius using hierarchical search
function SpatialHash:queryRadius(center, radius)
    local results = {}
    local checked = {}  -- Avoid duplicate checks
    
    -- Choose appropriate cell size based on radius
    local cellSize = radius * 2  -- Start with cell size ~2x radius
    local bestSize = self.cellSizes[#self.cellSizes]
    
    for _, size in ipairs(self.cellSizes) do
        if size >= cellSize then
            bestSize = size
            break
        end
    end
    
    -- Calculate cell range to check
    local minHash = self:hashPosition(center - util.vector3(radius, radius, radius), bestSize)
    local maxHash = self:hashPosition(center + util.vector3(radius, radius, radius), bestSize)
    
    -- Check all cells in range
    for x = minHash.x, maxHash.x do
        for y = minHash.y, maxHash.y do
            for z = minHash.z, maxHash.z do
                local key = string.format("%d,%d,%d", x, y, z)
                local cell = self.grids[bestSize][key]
                
                if cell then
                    for _, objData in ipairs(cell) do
                        local obj = objData.object
                        if obj:isValid() and not checked[obj] then
                            checked[obj] = true
                            local distSq = (objData.position - center):length2()
                            if distSq <= radius * radius then
                                table.insert(results, objData)
                            end
                        end
                    end
                end
            end
        end
    end
    
    return results
end

-- Clear all grids
function SpatialHash:clear()
    for _, size in ipairs(self.cellSizes) do
        self.grids[size] = {}
    end
end

-- Create module-level spatial hash
M.spatialHash = SpatialHash:new()

-- Frustum culling helper
function M.isInFrustum(position, margin)
    margin = margin or 100
    
    -- Get camera parameters
    local camPos = camera.getPosition()
    local camMatrix = camera.getViewMatrix()
    
    -- Transform to view space
    local viewPos = util.transform.apply(camMatrix, position - camPos)
    
    -- Simple frustum check (can be enhanced with full plane equations)
    if viewPos.z >= -margin then  -- Behind or very close to camera
        return false
    end
    
    -- Check field of view bounds
    local fov = camera.getFieldOfView()
    local halfTan = math.tan(fov / 2) * 1.2  -- 20% margin
    local maxXY = -viewPos.z * halfTan
    
    return math.abs(viewPos.x) <= maxXY and math.abs(viewPos.y) <= maxXY
end

-- Priority scoring for labels (which ones to show when crowded)
function M.calculatePriority(object, playerPos)
    local priority = 100
    
    -- Distance factor (closer = higher priority)
    local distance = (object.position - playerPos):length()
    priority = priority - (distance / 50)  -- Lose 1 point per 50 units
    
    -- Type bonus
    local objType = object.type
    if objType == require('openmw.types').NPC then
        priority = priority + 20  -- NPCs are important
    elseif objType == require('openmw.types').Container then
        priority = priority + 10  -- Containers are moderately important
    end
    
    -- Value bonus (if applicable)
    -- TODO: Add value-based priority for items
    
    return priority
end

-- Temporal coherence cache
local temporalCache = {
    frame = 0,
    visible = {},
    positions = {}
}

-- Update temporal cache
function M.updateTemporalCache(visibleObjects)
    temporalCache.frame = temporalCache.frame + 1
    
    -- Mark current visible objects
    local newVisible = {}
    for _, obj in ipairs(visibleObjects) do
        newVisible[obj] = true
        temporalCache.positions[obj] = obj.position
    end
    
    -- Clean up old entries
    for obj, _ in pairs(temporalCache.visible) do
        if not newVisible[obj] then
            temporalCache.visible[obj] = nil
            temporalCache.positions[obj] = nil
        end
    end
    
    temporalCache.visible = newVisible
end

-- Check if object was visible last frame (for smooth transitions)
function M.wasVisibleLastFrame(object)
    return temporalCache.visible[object] ~= nil
end

-- Get cached position for smoother updates
function M.getCachedPosition(object)
    return temporalCache.positions[object] or object.position
end

return M