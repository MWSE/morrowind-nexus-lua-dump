local util = require("openmw.util")
local ui = require("openmw.ui")

local FastTravel = {}
local COLORCHANGEAMMOUNT = 0.5

--------------------------------------------------
-- TEXTURES
--------------------------------------------------

local NODE_TEXTURE = "textures/DenyingProduct-Dynamic-Map/FTNodes.dds"
local HUB_TEXTURE  = "textures/DenyingProduct-Dynamic-Map/FTCircle.dds"

--------------------------------------------------
-- NODE DRAWING
--------------------------------------------------

local function placeNodeTexture(content, zoom, node, color, isHub)

    local tex = isHub and HUB_TEXTURE or NODE_TEXTURE
    local size = util.vector2(14, 14) * zoom
    local nodeColor = color
    if (isHub) then 
        size = util.vector2(25, 25) * zoom 
        nodeColor = util.color.rgb(
             math.min(color.r + COLORCHANGEAMMOUNT,1), 
             math.min(color.g + COLORCHANGEAMMOUNT,1), 
             math.min(color.b + COLORCHANGEAMMOUNT,1)
        )
    end

    table.insert(
        content,
        {
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = tex },
                size = size,
                position = util.vector2(node.mapX, node.mapY) * zoom,
                anchor = util.vector2(0.5, 0.5),
                color = nodeColor
            }
        }
    )
end

--------------------------------------------------
-- MERGE
--------------------------------------------------

function FastTravel.mergeNodes(base, extra)

    if not extra then return base end

    for name, data in pairs(extra) do

        if not base[name] then
            base[name] = { links = {} }
        end

        local existing = base[name].links
        local seen = {}

        for _, link in ipairs(existing) do
            seen[link] = true
        end

        for _, link in ipairs(data.links or {}) do
            if not seen[link] then
                table.insert(existing, link)
                seen[link] = true
            end
        end

    end

    return base
end

--------------------------------------------------
-- CLIQUE DETECTION
--------------------------------------------------

local function isLinked(nodes, a, b)
    for _, l in ipairs(nodes[a].links or {}) do
        if l == b then return true end
    end
    return false
end

local function isFullyConnected(nodes, group)

    for i = 1, #group do
        for j = i + 1, #group do
            if not (isLinked(nodes, group[i], group[j]) and isLinked(nodes, group[j], group[i])) then
                return false
            end
        end
    end

    return true
end

local function findCliques(nodes)

    local names = {}
    for n in pairs(nodes) do table.insert(names, n) end

    local used = {}
    local cliques = {}

    for i = 1, #names do

        local base = names[i]

        if not used[base] then

            local group = { base }

            for j = i + 1, #names do
                local other = names[j]

                if not used[other] then

                    local test = { table.unpack(group) }
                    table.insert(test, other)

                    if isFullyConnected(nodes, test) then
                        table.insert(group, other)
                    end

                end
            end

            if #group >= 3 then
                for _, n in ipairs(group) do used[n] = true end
                table.insert(cliques, group)
            end

        end
    end

    return cliques
end

--------------------------------------------------
-- APPLY WHEEL MODEL
--------------------------------------------------
local function inGroup(group, value)
    for _, v in ipairs(group) do
        if v == value then return true end
    end
    return false
end

function FastTravel.applyWheelAndSpoke(nodes)

    local cliques = findCliques(nodes)
    local hubIndex = 1

    for _, group in ipairs(cliques) do

        local hub = "Hub_" .. hubIndex
        hubIndex = hubIndex + 1

        nodes[hub] = { links = {} }

        for _, member in ipairs(group) do
            local newLinks = {}

            for _, link in ipairs(nodes[member].links) do
                if not inGroup(group, link) then
                    table.insert(newLinks, link)
                end
            end

            table.insert(newLinks, hub)
            nodes[member].links = newLinks
            table.insert(nodes[hub].links, member)
        end

    end

    return nodes
end

--------------------------------------------------
-- CELL LOOKUP
--------------------------------------------------

local function buildCellLookup(rawCells)

    local cellLookup = {}

    for _, cell in ipairs(rawCells or {}) do

        local name = cell.name:match("^(.-),") or cell.name

        if not cellLookup[name] then
            cellLookup[name] = { sumX = 0, sumY = 0, count = 0 }
        end

        local c = cellLookup[name]
        c.sumX = c.sumX + cell.x
        c.sumY = c.sumY + cell.y
        c.count = c.count + 1
    end

    for _, c in pairs(cellLookup) do
        c.x = c.sumX / c.count
        c.y = c.sumY / c.count
    end

    return cellLookup
end

--------------------------------------------------
-- EDGES
--------------------------------------------------

local function buildEdges(nodes)

    local edges = {}
    local seen = {}

    for name, data in pairs(nodes) do
        for _, target in ipairs(data.links) do

            local a, b = name, target
            local key = (a < b) and (a.."|"..b) or (b.."|"..a)

            if not seen[key] then
                seen[key] = true
                table.insert(edges, { a, b })
            end
        end
    end

    return edges
end

--------------------------------------------------
-- MAP NODES (WITH HUB SUPPORT)
--------------------------------------------------

local function buildMapNodes(nodes, cellLookup, gridToWorld, getMapPositionFromWorld)

    local mapNodes = {}

    for name, data in pairs(nodes) do

        local cell = cellLookup[name]

        -- HUB positioning
        if not cell and data.links then

            local sumX, sumY, count = 0, 0, 0

            for _, linked in ipairs(data.links) do
                local c = cellLookup[linked]
                if c then
                    sumX = sumX + c.x
                    sumY = sumY + c.y
                    count = count + 1
                end
            end

            if count > 0 then
                cell = {
                    x = sumX / count,
                    y = sumY / count
                }
            end
        end

        if cell then

            local wx, wy = gridToWorld(cell.x, cell.y)
            local mapPos = getMapPositionFromWorld(wx, wy)

            mapNodes[name] = {
                mapX = mapPos.x,
                mapY = mapPos.y
            }
        else
            -- print("[FAST TRAVEL] Missing cell:", name)
        end

    end

    return mapNodes
end

--------------------------------------------------
-- LINE TEXTURES
--------------------------------------------------

local lineTextures = {}

do
    local step = 2.8125
    for i = 0, (180 / step) - 1 do
        local angle = i * step
        local name = tostring(angle):gsub("%.", "_")
        lineTextures[tonumber(string.format("%.4f", angle))] =
            "line_" .. name .. ".dds"
    end
end

local function getLineTexture(dx, dy)

    local angle = math.deg(math.atan2(dy, dx))
    if angle < 0 then angle = angle + 180 end

    local step = 2.8125
    local snapped = math.floor((angle / step) + 0.5) * step
    snapped = snapped % 180
    snapped = tonumber(string.format("%.4f", snapped))

    return lineTextures[snapped]
end

--------------------------------------------------
-- MAIN PROCESS
--------------------------------------------------

function FastTravel.processNodes(rawCells, nodes, gridToWorld, getMapPositionFromWorld)

    nodes = FastTravel.applyWheelAndSpoke(nodes)

    local cellLookup = buildCellLookup(rawCells)
    local mapNodes = buildMapNodes(nodes, cellLookup, gridToWorld, getMapPositionFromWorld)
    local edges = buildEdges(nodes)

    return {
        mapNodes = mapNodes,
        edges = edges,
        originalNodes = nodes
    }
end

--------------------------------------------------
-- DRAW
--------------------------------------------------

function FastTravel.draw(content, zoom, processed, color)

    if not processed then return end

    local mapNodes = processed.mapNodes
    local edges = processed.edges
    local nodes = processed.originalNodes

    local placedNodes = {}

    -- draw lines
    for _, edge in ipairs(edges) do

        local a = mapNodes[edge[1]]
        local b = mapNodes[edge[2]]

        if a and b then

            local dx = b.mapX - a.mapX
            local dy = b.mapY - a.mapY
            local dist = math.sqrt(dx*dx + dy*dy)

            local tooLong = dist >= 500
            if (zoom == 0.25) then tooLong = false end
            --local tooSmallWhenZoomed = zoom <= 2 and dist < 125


            if not tooLong then

                local tex = "textures/DenyingProduct-Dynamic-Map/lines/Med_" .. getLineTexture(dx, dy)

                if dist > 225 then
                    tex = "textures/DenyingProduct-Dynamic-Map/lines/Long_" .. getLineTexture(dx, dy)
                elseif dist < 125 then
                    tex = "textures/DenyingProduct-Dynamic-Map/lines/Short_" .. getLineTexture(dx, dy)
                end

                local mid =
                    util.vector2(
                        (a.mapX + b.mapX)/2,
                        (a.mapY + b.mapY)/2
                    ) * zoom

                local isHubA = edge[1]:find("^Hub_") ~= nil
                local isHubB = edge[2]:find("^Hub_") ~= nil

                local lineColor = color
                if isHubA or isHubB then
                    lineColor = util.color.rgb(color.r + COLORCHANGEAMMOUNT, color.g + COLORCHANGEAMMOUNT, color.b + COLORCHANGEAMMOUNT)
                end
                if dist > 350 then 
                    --lineColor = util.color.rgb(color.r + COLORCHANGEAMMOUNT /2, color.g + COLORCHANGEAMMOUNT/2, color.b + COLORCHANGEAMMOUNT/2)
                end


                local alpha = 1
                if (zoom > 4) then
                    if(dist > 350) then alpha = 0.2 end           
                end
                if (zoom == 4) then
                    if(dist > 350) then alpha = 0.5 end           
                end

                table.insert(content, {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = tex },
                        size = util.vector2(dist*zoom, dist*zoom),
                        position = mid,
                        anchor = util.vector2(0.5, 0.5),
                        color = lineColor,
                        alpha = alpha
                    }
                })
            end
        end
    end

    -- draw nodes
    for name, node in pairs(mapNodes) do

        if not placedNodes[name] then

            local isHub = name:find("^Hub_") ~= nil
            placeNodeTexture(content, zoom, node, color, isHub)

            placedNodes[name] = true
        end
    end
end

return FastTravel