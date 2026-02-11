-- Texture dimension detection for various image formats
-- Reads file headers via OpenMW's VFS to extract width/height

local vfs = require('openmw.vfs')

-- Read bytes as little-endian unsigned integer
local function readLE(bytes, offset, count)
    local value = 0
    for i = 0, count - 1 do
        value = value + bytes:byte(offset + i + 1) * (256 ^ i)
    end
    return value
end

-- Read bytes as big-endian unsigned integer
local function readBE(bytes, offset, count)
    local value = 0
    for i = 0, count - 1 do
        value = value * 256 + bytes:byte(offset + i + 1)
    end
    return value
end

-- Parse TGA header (18 bytes minimum)
local function parseTGA(f)
    local header = f:read(18)
    if not header or #header < 18 then return nil end

    local width = readLE(header, 12, 2)
    local height = readLE(header, 14, 2)

    if width > 0 and height > 0 and width < 65536 and height < 65536 then
        return width, height
    end
    return nil
end

-- Parse DDS header (128 bytes minimum for standard DDS)
local function parseDDS(f)
    local header = f:read(128)
    if not header or #header < 128 then return nil end

    -- Check magic number "DDS "
    if header:sub(1, 4) ~= 'DDS ' then return nil end

    -- Height at offset 12, width at offset 16 (after 4-byte magic)
    local height = readLE(header, 12, 4)
    local width = readLE(header, 16, 4)

    if width > 0 and height > 0 then
        return width, height
    end
    return nil
end

-- Parse JPEG to find dimensions (need to scan for SOF marker)
local function parseJPEG(f)
    local header = f:read(2)
    if not header or #header < 2 then return nil end

    -- Check JPEG magic (FFD8)
    if header:byte(1) ~= 0xFF or header:byte(2) ~= 0xD8 then return nil end

    -- Scan through markers to find SOF (Start of Frame)
    -- SOF markers: FFC0-FFCF (except FFC4, FFC8, FFCC which are other things)
    while true do
        local marker = f:read(2)
        if not marker or #marker < 2 then return nil end

        if marker:byte(1) ~= 0xFF then return nil end

        local markerType = marker:byte(2)

        -- Skip padding FF bytes
        while markerType == 0xFF do
            marker = f:read(1)
            if not marker then return nil end
            markerType = marker:byte(1)
        end

        -- SOF0-SOF3, SOF5-SOF7, SOF9-SOF11, SOF13-SOF15 contain dimensions
        if (markerType >= 0xC0 and markerType <= 0xC3) or
           (markerType >= 0xC5 and markerType <= 0xC7) or
           (markerType >= 0xC9 and markerType <= 0xCB) or
           (markerType >= 0xCD and markerType <= 0xCF) then
            local data = f:read(7)
            if not data or #data < 7 then return nil end

            local height = readBE(data, 3, 2)
            local width = readBE(data, 5, 2)

            if width > 0 and height > 0 then
                return width, height
            end
            return nil
        end

        -- Read segment length and skip
        local lenBytes = f:read(2)
        if not lenBytes or #lenBytes < 2 then return nil end

        local segmentLen = readBE(lenBytes, 0, 2)
        if segmentLen < 2 then return nil end

        -- Skip segment data (length includes the 2 length bytes we already read)
        local skipLen = segmentLen - 2
        if skipLen > 0 then
            local skipped = f:read(skipLen)
            if not skipped or #skipped < skipLen then return nil end
        end
    end
end

-- Get dimensions for a texture file
-- Returns width, height or nil if format unknown/file not found
local function getDimensions(path)
    if not vfs.fileExists(path) then
        return nil
    end

    local f = vfs.open(path)
    if not f then
        return nil
    end

    local width, height
    local lowerPath = path:lower()

    if lowerPath:match('%.tga$') then
        width, height = parseTGA(f)
    elseif lowerPath:match('%.dds$') then
        width, height = parseDDS(f)
    elseif lowerPath:match('%.jpe?g$') then
        width, height = parseJPEG(f)
    end

    f:close()
    return width, height
end

-- Known aspect ratio of the Vvardenfell paper map (21637x25191 original scan)
-- Used to calculate content width for square padded textures
local MAP_ASPECT_RATIO = 21637 / 25191

-- Find the first existing texture from a list of paths
-- Returns path, textureWidth, textureHeight, contentWidth, contentHeight or nil if none found
-- For square textures, assumes right-side padding with content scaled to fill height
local function findTexture(paths)
    for _, path in ipairs(paths) do
        if vfs.fileExists(path) then
            local width, height = getDimensions(path)
            if width and height then
                local contentW, contentH = width, height
                -- Square texture: assume it's padded on the right (content left-aligned)
                -- Content fills full height, width calculated from known aspect ratio
                if width == height then
                    contentW = math.floor(height * MAP_ASPECT_RATIO + 0.5)
                    contentH = height
                end
                return path, width, height, contentW, contentH
            end
        end
    end
    return nil
end

return {
    getDimensions = getDimensions,
    findTexture = findTexture,
}
