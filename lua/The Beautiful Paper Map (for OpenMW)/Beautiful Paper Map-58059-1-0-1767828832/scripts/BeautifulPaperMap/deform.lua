-- Map deformation module
-- Uses Delaunay triangulation + barycentric interpolation to map
-- world coordinates to hand-drawn map coordinates

local deform = {}

-- Control points data (will be populated from exported data)
local controlPoints = nil
local triangles = nil

-- Load control points from data table
-- Expected format: { points = { { world = {x, y}, paper = {x, y}, name = "..." }, ... } }
function deform.loadPoints(data)
    controlPoints = data.points
    if #controlPoints >= 3 then
        triangles = deform.triangulate(controlPoints)
    end
    return #controlPoints
end

-- Delaunay triangulation using Bowyer-Watson algorithm
-- Returns list of triangles, each with indices into controlPoints
function deform.triangulate(points)
    local n = #points

    -- Find bounds of all points to create appropriate super-triangle
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
    for _, p in ipairs(points) do
        local coords = p.world
        minX = math.min(minX, coords[1])
        maxX = math.max(maxX, coords[1])
        minY = math.min(minY, coords[2])
        maxY = math.max(maxY, coords[2])
    end

    -- Create super-triangle that contains all points with margin
    local dx = (maxX - minX) * 2
    local dy = (maxY - minY) * 2
    local midX = (minX + maxX) / 2
    local midY = (minY + maxY) / 2

    local superTriangle = {
        { world = { midX - dx, midY - dy * 2 } },
        { world = { midX + dx * 2, midY - dy } },
        { world = { midX - dx, midY + dy * 2 } }
    }

    -- Add super-triangle vertices to points temporarily
    local allPoints = {}
    for i, p in ipairs(points) do
        allPoints[i] = p
    end
    allPoints[n + 1] = superTriangle[1]
    allPoints[n + 2] = superTriangle[2]
    allPoints[n + 3] = superTriangle[3]

    -- Start with super-triangle
    local tris = { { n + 1, n + 2, n + 3 } }

    -- Add each point one at a time
    for i = 1, n do
        local coords = points[i].world
        local px = coords[1]
        local py = coords[2]

        -- Find all triangles whose circumcircle contains this point
        local badTriangles = {}
        for j, tri in ipairs(tris) do
            local p1 = allPoints[tri[1]].world
            local p2 = allPoints[tri[2]].world
            local p3 = allPoints[tri[3]].world

            if deform.inCircumcircle(px, py, p1[1], p1[2], p2[1], p2[2], p3[1], p3[2]) then
                table.insert(badTriangles, j)
            end
        end

        -- Find the boundary polygon of the bad triangles (polygon hole)
        local polygon = {}
        for _, j in ipairs(badTriangles) do
            local tri = tris[j]
            local edges = {
                { tri[1], tri[2] },
                { tri[2], tri[3] },
                { tri[3], tri[1] }
            }
            for _, edge in ipairs(edges) do
                -- Check if this edge is shared with another bad triangle
                local shared = false
                for _, k in ipairs(badTriangles) do
                    if k ~= j then
                        local otherTri = tris[k]
                        if deform.hasEdge(otherTri, edge[1], edge[2]) then
                            shared = true
                            break
                        end
                    end
                end
                if not shared then
                    table.insert(polygon, edge)
                end
            end
        end

        -- Remove bad triangles (in reverse order to preserve indices)
        table.sort(badTriangles, function(a, b) return a > b end)
        for _, j in ipairs(badTriangles) do
            table.remove(tris, j)
        end

        -- Create new triangles from polygon edges to new point
        for _, edge in ipairs(polygon) do
            table.insert(tris, { edge[1], edge[2], i })
        end
    end

    -- Remove triangles that share vertices with super-triangle
    local result = {}
    for _, tri in ipairs(tris) do
        if tri[1] <= n and tri[2] <= n and tri[3] <= n then
            table.insert(result, tri)
        end
    end

    return result
end

-- Check if triangle has edge (order independent)
function deform.hasEdge(tri, a, b)
    local has_a = tri[1] == a or tri[2] == a or tri[3] == a
    local has_b = tri[1] == b or tri[2] == b or tri[3] == b
    return has_a and has_b
end

-- Check if point (px, py) is inside circumcircle of triangle
function deform.inCircumcircle(px, py, x1, y1, x2, y2, x3, y3)
    local ax = x1 - px
    local ay = y1 - py
    local bx = x2 - px
    local by = y2 - py
    local cx = x3 - px
    local cy = y3 - py

    local det = (ax * ax + ay * ay) * (bx * cy - cx * by)
              - (bx * bx + by * by) * (ax * cy - cx * ay)
              + (cx * cx + cy * cy) * (ax * by - bx * ay)

    -- For counter-clockwise triangles, point is inside if det > 0
    -- Need to check triangle orientation
    local orient = (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)
    if orient < 0 then
        return det < 0
    else
        return det > 0
    end
end

-- Calculate barycentric coordinates for point (px, py) in triangle
function deform.barycentric(px, py, x1, y1, x2, y2, x3, y3)
    local denom = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
    if math.abs(denom) < 1e-10 then
        return nil -- Degenerate triangle
    end

    local w1 = ((y2 - y3) * (px - x3) + (x3 - x2) * (py - y3)) / denom
    local w2 = ((y3 - y1) * (px - x3) + (x1 - x3) * (py - y3)) / denom
    local w3 = 1 - w1 - w2

    return w1, w2, w3
end

-- Check if barycentric coordinates indicate point is inside triangle
function deform.isInsideTriangle(w1, w2, w3)
    return w1 >= 0 and w2 >= 0 and w3 >= 0
end

-- Transform world coordinates to paper map coordinates
-- Input: world coords (game units)
-- Output: normalized paper map coords (0-1)
function deform.transform(worldX, worldY)
    if not triangles or #triangles == 0 then
        -- No triangulation, return 0.5, 0.5 as fallback
        return 0.5, 0.5
    end

    -- Find which triangle contains this point
    for _, tri in ipairs(triangles) do
        local p1 = controlPoints[tri[1]]
        local p2 = controlPoints[tri[2]]
        local p3 = controlPoints[tri[3]]

        local w1, w2, w3 = deform.barycentric(
            worldX, worldY,
            p1.world[1], p1.world[2],
            p2.world[1], p2.world[2],
            p3.world[1], p3.world[2]
        )

        if w1 and deform.isInsideTriangle(w1, w2, w3) then
            -- Interpolate paper coordinates using same barycentric weights
            local paperX = w1 * p1.paper[1] + w2 * p2.paper[1] + w3 * p3.paper[1]
            local paperY = w1 * p1.paper[2] + w2 * p2.paper[2] + w3 * p3.paper[2]
            return paperX, paperY
        end
    end

    -- Point is outside all triangles - find nearest triangle and extrapolate
    return deform.extrapolate(worldX, worldY)
end

-- Extrapolate for points outside the triangulation
-- Uses nearest triangle (allows barycentric coords outside 0-1)
function deform.extrapolate(worldX, worldY)
    if not triangles or #triangles == 0 then
        return 0.5, 0.5
    end

    local bestTri = nil
    local bestW1, bestW2, bestW3 = nil, nil, nil
    local bestDist = math.huge

    for _, tri in ipairs(triangles) do
        local p1 = controlPoints[tri[1]]
        local p2 = controlPoints[tri[2]]
        local p3 = controlPoints[tri[3]]

        local w1, w2, w3 = deform.barycentric(
            worldX, worldY,
            p1.world[1], p1.world[2],
            p2.world[1], p2.world[2],
            p3.world[1], p3.world[2]
        )

        if w1 then
            -- Distance from being inside (0 if inside)
            local dist = 0
            if w1 < 0 then dist = dist + w1 * w1 end
            if w2 < 0 then dist = dist + w2 * w2 end
            if w3 < 0 then dist = dist + w3 * w3 end

            if dist < bestDist then
                bestDist = dist
                bestTri = tri
                bestW1, bestW2, bestW3 = w1, w2, w3
            end
        end
    end

    if bestTri then
        local p1 = controlPoints[bestTri[1]]
        local p2 = controlPoints[bestTri[2]]
        local p3 = controlPoints[bestTri[3]]

        local paperX = bestW1 * p1.paper[1] + bestW2 * p2.paper[1] + bestW3 * p3.paper[1]
        local paperY = bestW1 * p1.paper[2] + bestW2 * p2.paper[2] + bestW3 * p3.paper[2]
        return paperX, paperY
    end

    -- Fallback
    return 0.5, 0.5
end

-- Debug: get triangulation info
function deform.getDebugInfo()
    return {
        numPoints = controlPoints and #controlPoints or 0,
        numTriangles = triangles and #triangles or 0
    }
end

-- Debug: get all triangles (for visualization)
function deform.getTriangles()
    if not triangles then return {} end

    local result = {}
    for _, tri in ipairs(triangles) do
        table.insert(result, {
            controlPoints[tri[1]],
            controlPoints[tri[2]],
            controlPoints[tri[3]]
        })
    end
    return result
end

return deform
