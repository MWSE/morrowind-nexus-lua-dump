-- labelLayout_jitter.lua: Intelligent jittering with connecting lines
-- Spreads labels to avoid overlap while maintaining clear connections to objects

local util = require('openmw.util')
local ui = require('openmw.ui')

local M = {}

-- Helper for creating colors
local col = util.color.rgb

-- Helper function to normalize a vector
local function normalizeVector(vec)
    local len = vec:length()
    if len > 0 then
        return vec / len
    else
        return vec
    end
end

-- Configuration for jittering behavior
local CONFIG = {
    -- Minimum distance between labels
    MIN_LABEL_SPACING = 40,
    
    -- Maximum distance a label can be from its object
    MAX_LABEL_DISTANCE = 200,
    
    -- Get screen-scaled offset
    getScaledOffset = function(baseOffset)
        local ui = require('openmw.ui')
        local screenSize = ui.screenSize()
        -- Scale based on screen height (1080p as baseline)
        local scale = math.max(1.0, screenSize.y / 1080)
        return baseOffset * scale
    end,
    
    -- Preferred label positions (relative to object)
    -- These will be scaled based on screen resolution
    PREFERRED_POSITIONS_BASE = {
        util.vector2(0, -15),     -- Slightly above center
        util.vector2(0, -25),     -- Above
        util.vector2(35, -20),    -- Upper right
        util.vector2(-35, -20),   -- Upper left
        util.vector2(45, -5),     -- Right (slightly up)
        util.vector2(-45, -5),    -- Left (slightly up)
        util.vector2(35, 15),     -- Lower right
        util.vector2(-35, 15),    -- Lower left
        util.vector2(0, 25),      -- Below
    },
    
    -- Line appearance
    LINE_COLOR = col(0.8, 0.8, 0.6, 0.8),  -- More visible yellow-white
    LINE_THICKNESS = 2,  -- Thicker line for visibility
    
    -- Jitter parameters
    JITTER_ITERATIONS = 10,  -- Max attempts to find good position
    FORCE_STRENGTH = 30,     -- Repulsion force between labels
}

-- Get scaled preferred positions
function CONFIG.getPreferredPositions()
    local positions = {}
    local scale = CONFIG.getScaledOffset(1.0)
    for _, basePos in ipairs(CONFIG.PREFERRED_POSITIONS_BASE) do
        table.insert(positions, basePos * scale)
    end
    return positions
end

-- Label placement solver with jittering
local JitterSolver = {}
JitterSolver.__index = JitterSolver

function JitterSolver:new()
    local self = setmetatable({}, JitterSolver)
    self.labels = {}
    self.connections = {}
    return self
end

-- Add a label to be placed
function JitterSolver:addLabel(objectScreenPos, labelWidth, labelHeight, priority, data)
    table.insert(self.labels, {
        objectPos = objectScreenPos,
        width = labelWidth,
        height = labelHeight,
        priority = priority,
        data = data,
        finalPos = nil,
        preferredPos = nil
    })
end

-- Solve label positions with jittering
function JitterSolver:solve()
    -- Sort by priority (highest first)
    table.sort(self.labels, function(a, b)
        return a.priority > b.priority
    end)
    
    -- First pass: try preferred positions
    for i, label in ipairs(self.labels) do
        label.finalPos = self:findBestPosition(label, i)
    end
    
    -- Second pass: apply repulsion forces to spread overlapping labels
    for iteration = 1, CONFIG.JITTER_ITERATIONS do
        local forcesApplied = false
        
        for i, label1 in ipairs(self.labels) do
            local force = util.vector2(0, 0)
            
            -- Calculate repulsion from other labels
            for j, label2 in ipairs(self.labels) do
                if i ~= j then
                    local repulsion = self:calculateRepulsion(label1, label2)
                    force = force + repulsion
                    if repulsion:length() > 0.1 then
                        forcesApplied = true
                    end
                end
            end
            
            -- Apply force with constraints
            if force:length() > 0.1 then
                local newPos = label1.finalPos + force
                
                -- Constrain to max distance from object
                local distFromObject = (newPos - label1.objectPos):length()
                if distFromObject > CONFIG.MAX_LABEL_DISTANCE then
                    local dir = normalizeVector(newPos - label1.objectPos)
                    newPos = label1.objectPos + dir * CONFIG.MAX_LABEL_DISTANCE
                end
                
                label1.finalPos = newPos
            end
        end
        
        -- Stop if no significant forces
        if not forcesApplied then
            break
        end
    end
    
    -- Build result with line connections
    local results = {}
    for _, label in ipairs(self.labels) do
        table.insert(results, {
            labelPos = label.finalPos,
            objectPos = label.objectPos,
            showLine = (label.finalPos - label.objectPos):length() > 20,  -- Show line if far from object
            data = label.data
        })
    end
    
    return results
end

-- Find best initial position for a label
function JitterSolver:findBestPosition(label, index)
    local bestPos = label.objectPos
    local bestScore = -1000
    
    -- Get scaled positions
    local preferredPositions = CONFIG.getPreferredPositions()
    
    -- Try each preferred position
    for i, offset in ipairs(preferredPositions) do
        local candidatePos = label.objectPos + offset
        local score = self:scorePosition(candidatePos, label, index)
        
        -- Prefer positions that match the label's index (spreads them out)
        if i == ((index - 1) % #preferredPositions) + 1 then
            score = score + 10
        end
        
        if score > bestScore then
            bestScore = score
            bestPos = candidatePos
        end
    end
    
    return bestPos
end

-- Score a position based on overlap and distance
function JitterSolver:scorePosition(pos, label, currentIndex)
    local score = 100
    
    -- Penalize positions that overlap with already-placed labels
    for i = 1, currentIndex - 1 do
        local other = self.labels[i]
        if self:labelsOverlap(pos, label.width, label.height, 
                             other.finalPos, other.width, other.height) then
            score = score - 50
        else
            -- Small penalty for being close
            local dist = (pos - other.finalPos):length()
            if dist < CONFIG.MIN_LABEL_SPACING * 2 then
                score = score - (CONFIG.MIN_LABEL_SPACING * 2 - dist) / 4
            end
        end
    end
    
    -- Prefer positions closer to object (but not too close)
    local distFromObject = (pos - label.objectPos):length()
    if distFromObject < 30 then
        score = score - 20  -- Too close
    elseif distFromObject > 100 then
        score = score - (distFromObject - 100) / 10  -- Getting far
    end
    
    -- Prefer positions above objects (more natural)
    if pos.y < label.objectPos.y then
        score = score + 5
    end
    
    return score
end

-- Calculate repulsion force between two labels
function JitterSolver:calculateRepulsion(label1, label2)
    local delta = label1.finalPos - label2.finalPos
    local distance = delta:length()
    
    -- Check for overlap
    if self:labelsOverlap(label1.finalPos, label1.width, label1.height,
                         label2.finalPos, label2.width, label2.height) then
        -- Strong repulsion for overlapping labels
        if distance < 0.1 then
            -- Labels are at same position, push in random direction
            return util.vector2(math.random() - 0.5, math.random() - 0.5) * CONFIG.FORCE_STRENGTH
        else
            -- Push away from each other
            return normalizeVector(delta) * CONFIG.FORCE_STRENGTH
        end
    elseif distance < CONFIG.MIN_LABEL_SPACING then
        -- Mild repulsion for close labels
        local force = (CONFIG.MIN_LABEL_SPACING - distance) / CONFIG.MIN_LABEL_SPACING
        return normalizeVector(delta) * force * CONFIG.FORCE_STRENGTH * 0.5
    end
    
    return util.vector2(0, 0)
end

-- Check if two labels overlap
function JitterSolver:labelsOverlap(pos1, w1, h1, pos2, w2, h2)
    local left1 = pos1.x - w1/2
    local right1 = pos1.x + w1/2
    local top1 = pos1.y - h1
    local bottom1 = pos1.y
    
    local left2 = pos2.x - w2/2
    local right2 = pos2.x + w2/2
    local top2 = pos2.y - h2
    local bottom2 = pos2.y
    
    return not (right1 < left2 or right2 < left1 or bottom1 < top2 or bottom2 < top1)
end

-- Clear solver
function JitterSolver:clear()
    self.labels = {}
    self.connections = {}
end

-- Module API
M.solver = JitterSolver:new()

-- Create a connecting line UI element
function M.createConnectingLine(startPos, endPos)
    local delta = endPos - startPos
    local length = delta:length()
    
    if length < 5 then
        return nil  -- Too short to show
    end
    
    local angle = math.atan2(delta.y, delta.x)
    local midPoint = startPos + delta * 0.5
    
    return ui.create({
        layer = 'HUD',
        type = ui.TYPE.Container,
        props = {
            -- Thin line as stretched rectangle
            backgroundColor = CONFIG.LINE_COLOR,
            size = util.vector2(length, CONFIG.LINE_THICKNESS),
            position = midPoint,
            anchor = util.vector2(0.5, 0.5),
            rotation = angle,
            
            -- Slight transparency
            alpha = 0.6
        }
    })
end

-- Alternative: Create dotted/dashed line
function M.createDottedLine(startPos, endPos, dashLength)
    dashLength = dashLength or 5
    
    local delta = endPos - startPos
    local length = delta:length()
    local direction = normalizeVector(delta)
    
    local dashes = {}
    local numDashes = math.floor(length / (dashLength * 2))
    
    for i = 0, numDashes do
        local dashStart = startPos + direction * (i * dashLength * 2)
        local dashEnd = dashStart + direction * dashLength
        
        table.insert(dashes, ui.create({
            layer = 'HUD',
            type = ui.TYPE.Container,
            props = {
                backgroundColor = CONFIG.LINE_COLOR,
                size = util.vector2(dashLength, CONFIG.LINE_THICKNESS),
                position = dashStart + direction * (dashLength / 2),
                anchor = util.vector2(0.5, 0.5),
                rotation = math.atan2(delta.y, delta.x)
            }
        }))
    end
    
    return dashes
end

-- Create curved line (bezier) for more organic look
function M.createCurvedLine(startPos, endPos, curveAmount)
    curveAmount = curveAmount or 20
    
    -- Calculate control point for bezier curve
    local midPoint = (startPos + endPos) * 0.5
    local perpendicular = normalizeVector(util.vector2(-(endPos.y - startPos.y), endPos.x - startPos.x))
    local controlPoint = midPoint + perpendicular * curveAmount
    
    -- Approximate bezier with line segments
    local segments = {}
    local numSegments = 8
    
    for i = 0, numSegments - 1 do
        local t1 = i / numSegments
        local t2 = (i + 1) / numSegments
        
        -- Bezier formula
        local p1 = startPos * (1-t1)^2 + controlPoint * 2*t1*(1-t1) + endPos * t1^2
        local p2 = startPos * (1-t2)^2 + controlPoint * 2*t2*(1-t2) + endPos * t2^2
        
        local delta = p2 - p1
        local length = delta:length()
        local angle = math.atan2(delta.y, delta.x)
        
        table.insert(segments, ui.create({
            layer = 'HUD',
            type = ui.TYPE.Container,
            props = {
                backgroundColor = CONFIG.LINE_COLOR,
                size = util.vector2(length, CONFIG.LINE_THICKNESS),
                position = (p1 + p2) * 0.5,
                anchor = util.vector2(0.5, 0.5),
                rotation = angle
            }
        }))
    end
    
    return segments
end

-- Smart line style selection based on context
function M.getLineStyle(startPos, endPos, isGrouped, priority)
    local distance = (endPos - startPos):length()
    
    if distance < 20 then
        return "none"  -- Too close, no line needed (matches showLine threshold)
    elseif isGrouped then
        return "curved"  -- Curved lines for grouped items
    elseif priority > 80 then
        return "solid"  -- Important items get solid lines
    else
        return "dotted"  -- Less important items get dotted lines
    end
end

return M