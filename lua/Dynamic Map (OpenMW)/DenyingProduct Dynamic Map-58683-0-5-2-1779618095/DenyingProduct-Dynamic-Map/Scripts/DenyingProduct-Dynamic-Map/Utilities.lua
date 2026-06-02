local util = require("openmw.util")

local Utilities = {}

function Utilities.isVisible(position, padding, mapOffset, frameSize)

    padding = padding or 0

    local left = -mapOffset.x - padding

    local top = -mapOffset.y - padding

    local right = left + frameSize.x

    local bottom = top + frameSize.y

    return
        position.x >= left
        and position.x <= right
        and position.y >= top
        and position.y <= bottom
end

function Utilities.clampMapOffset(MAP_COLUMNS,MAP_ROWS,zoom,frameSize,mapOffset)
    local mapWidth =  1024 * (MAP_COLUMNS) * zoom
    local mapHeight = 1024 * (MAP_ROWS) * zoom
    local halfFrameX = frameSize.x / 2
    local halfFrameY = frameSize.y / 2
    local minX = halfFrameX - mapWidth
    local minY = halfFrameY - mapHeight
    local maxX = halfFrameX
    local maxY = halfFrameY

    return util.vector2(
        Utilities.clamp(mapOffset.x, minX, maxX),
        Utilities.clamp(mapOffset.y, minY, maxY)
    )
end

--deprecated, noved to maprenderer
function Utilities.getVisibleTileBounds(mapOffset,zoom,frameSize)

    local tileSize = 1024 * zoom

    local left   = -mapOffset.x
    local top    = -mapOffset.y
    local right  = frameSize.x - mapOffset.x
    local bottom = frameSize.y - mapOffset.y

    local minX = math.floor(left / tileSize)
    local minY = math.floor(top / tileSize)
    local maxX = math.floor(right / tileSize)
    local maxY = math.floor(bottom / tileSize)

    return
        minX ,
        minY,
        maxX,
        maxY
end

function Utilities.clamp(value, minVal, maxVal)
    return math.max(minVal, math.min(value, maxVal))
end

function Utilities.gridToWorld(gridX, gridY)
    local cellSize = 8192
    local cellOffset = cellSize / 2 -- to center of cell
    return gridX * cellSize + cellOffset, gridY * cellSize + cellOffset
end

function Utilities.getMapPositionFromWorld(scale, zeroX, zeroY, x, y)
	return util.vector2(
        zeroX + x * scale,
        zeroY - y * scale
    )
end

function Utilities.wrapWords(text, maxLen)

    -- split on space or any words longer than MaxLen. make an exception to not split if the remaining part is 2 characters or less to avoid orphaned letters.
    local words = {}
    for w in text:gmatch("%S+") do
        while #w > maxLen do
            local part = w:sub(1, maxLen - 1)
            w = w:sub(maxLen)
            if #w <= 2 then
                part = part .. w
                w = ""
            else
                part = part .. "-"
            end
            table.insert(words, part)
        end
        table.insert(words, w)
    end

    -- POP array and build lines
    local result = {}
    local line = ""
    while #words > 0 do
        local word = table.remove(words, 1) 
        if line == "" then
            line = word
        elseif #line + 1 + #word <= maxLen then
            line = line .. " " .. word
        else
            table.insert(result, line)
            line = word
        end
    end

    -- push last line
    if line ~= "" then
        table.insert(result, line)
    end
    return table.concat(result, "\n")

end

function Utilities.getTextSize(mergeCount,zoom)
    -- normal single cell markers
    local textsize = 5
    -- increase size based on merge count (more merged cells = bigger text)
    if(mergeCount > 1) then textsize = 12 end
    if(mergeCount >= 3) then textsize = 16 end
    if(mergeCount >= 5) then textsize = 20 end
    if(zoom == 1) then
        if(mergeCount > 1) then textsize = 15 end
        if(mergeCount >= 3) then textsize = 20 end
        if(mergeCount >= 5) then textsize = 20 end
    end
    if(zoom == 0.5) then
        if(mergeCount > 1) then textsize = 0 end
        if(mergeCount >= 3) then textsize = 30 end
        if(mergeCount >= 5) then textsize = 30 end
        if(mergeCount >= 6) then textsize = 45 end
    end
    if(zoom == 0.25) then
        if(mergeCount > 1) then textsize = 0 end
        if(mergeCount >= 3) then textsize = 0 end
        if(mergeCount >= 5) then textsize = 40 end
        if(mergeCount >= 6) then textsize = 75 end
    end
    if(zoom >= 10) then textsize = 0.5 end
    return textsize 
end

return Utilities