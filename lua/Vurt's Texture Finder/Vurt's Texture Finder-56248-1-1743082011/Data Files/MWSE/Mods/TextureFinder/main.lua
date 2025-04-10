local config = require("TextureFinder.mcm") -- Load settings, or fallback below

-- File path for the log (in MWSE\mods\TextureFinder\textures.log)
local logFilePath = "Data Files\\MWSE\\mods\\TextureFinder\\textures.log"
local loggedTextures = {} -- Table to track unique textures in this session

-- Helper function to normalize texture name (force .dds and optionally strip path)
local function normalizeTextureName(texture, showFullPaths)
    -- Replace any extension with .dds
    local normalized = texture:gsub("%..+$", ".dds")
    -- If not showing full paths, extract just the filename
    if not showFullPaths then
        normalized = normalized:match("[^\\]+%.dds$") or normalized
    end
    return normalized
end

-- Helper function to overwrite the log file with unique textures
local function updateLogFile(newTexture)
    if newTexture then
        print("[TextureFinder] New texture detected: " .. newTexture)
    end
    local file = io.open(logFilePath, "w") -- "w" mode overwrites the file
    if file then
        file:write("Unique textures hit this session:\n")
        for texture, _ in pairs(loggedTextures) do
            local logTexture = normalizeTextureName(texture, config.showFullPaths)
            print("[TextureFinder] Writing texture to log: " .. logTexture)
            file:write(logTexture .. "\n")
        end
        file:close()
        print("[TextureFinder] Log file updated.")
    else
        print("[TextureFinder] Failed to open log file for writing.")
    end
end

local function onAttack(e)
    if not config.enabled then return end -- Only run if enabled

    if not tes3.mobilePlayer or not e.reference then
        return
    end

    -- Raycast from the player's camera
    local rayhit = tes3.rayTest({
        position = tes3.getCameraPosition(),
        direction = tes3.getCameraVector(),
        ignore = { tes3.player } -- Ignore player model
    })

    if rayhit and rayhit.object then
        local obj = rayhit.object
        if obj.texturingProperty and obj.texturingProperty.maps then
            local primaryTexture = obj.texturingProperty.maps[1] and obj.texturingProperty.maps[1].texture and obj.texturingProperty.maps[1].texture.fileName
            if primaryTexture then
                local displayTexture = normalizeTextureName(primaryTexture, config.showFullPaths)
                tes3.messageBox("Texture: %s", displayTexture) -- Show normalized primary texture
            else
                tes3.messageBox("No texture found on object.")
            end

            -- Log all textures
            for i, map in ipairs(obj.texturingProperty.maps) do
                if map and map.texture and map.texture.fileName then
                    local textureName = map.texture.fileName
                    if not loggedTextures[textureName] then
                        loggedTextures[textureName] = true
                        print("[TextureFinder] Adding texture to table: " .. textureName)
                        updateLogFile(textureName) -- Pass the new texture to trigger update
                    else
                        print("[TextureFinder] Texture already logged: " .. textureName)
                    end
                end
            end
        else
            tes3.messageBox("No texture found on object.")
        end
    else
        -- Check for land texture if no object is hit
        local cell = tes3.player.cell
        if not cell.isInterior then
            local pos = tes3.player.position
            local gridX = math.floor(pos.x / 8192)
            local gridY = math.floor(pos.y / 8192)
            local land = tes3.getLandscapeTexture(gridX, gridY)
            if land and land.fileName then
                local textureName = land.fileName
                local displayTexture = normalizeTextureName(textureName, config.showFullPaths)
                tes3.messageBox("Land Texture: %s", displayTexture)
                -- Log land texture if not already logged
                if not loggedTextures[textureName] then
                    loggedTextures[textureName] = true
                    print("[TextureFinder] Adding land texture to table: " .. textureName)
                    updateLogFile(textureName) -- Pass the new texture to trigger update
                else
                    print("[TextureFinder] Land texture already logged: " .. textureName)
                end
            else
                tes3.messageBox("No object detected.")
            end
        else
            tes3.messageBox("No object detected.")
        end
    end
end

-- Register attack event and initialize log
local function onInitialized()
    -- Clear the log file and table on startup
    loggedTextures = {} -- Reset the table
    local file = io.open(logFilePath, "w")
    if file then
        file:write("Unique textures hit this session:\n")
        file:close()
        print("[TextureFinder] Log file initialized.")
    else
        print("[TextureFinder] Failed to initialize log file.")
    end
    event.register("attack", onAttack)
    print("[TextureFinder] Mod initialized. Unique textures will be logged to textures.log.")
end

event.register("initialized", onInitialized)