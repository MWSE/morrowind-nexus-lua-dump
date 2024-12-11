---@class DarkShard.Common
local common = {}
common.config = require("mer.darkShard.config")
local MWSELogger = require("logging.logger")
---@type table<string, mwseLogger>
common.loggers = {}
function common.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("%s - %s",
            common.config.metadata.package.name, serviceName),
        logLevel = common.config.mcm.logLevel,
        includeTimestamp = true,
    }
    common.loggers[serviceName] = logger
    return logger
end
local logger = common.createLogger("common")

---@return string #The version of the mod
function common.getVersion()
    return common.config.metadata.package.version
end

local function isLuaFile(file) return file:sub(-4, -1) == ".lua" end
local function isInitFile(file) return file == "init.lua" end
local function isDirectory(path)
    local attr = lfs.attributes(path)
    return attr and attr.mode == "directory"
end

function common.initAll(path)
    path = "Data Files/MWSE/mods/" .. path .. "/"
    for file in lfs.dir(path) do
        local fullPath = path .. file
        if isLuaFile(file) and not isInitFile(file) then
            logger:debug("Executing file: %s", file)
            dofile(fullPath)
        end
    end
end

function common.replaceTexture(node, newTexturePath)
    local texture = niSourceTexture.createFromPath(newTexturePath, false)
    if not texture then
        logger:error("Failed to load texture: %s", newTexturePath)
        return
    end
    ---@type niTexturingProperty
    local clonedProp = node:detachProperty(ni.propertyType.texturing):clone()
    clonedProp.baseMap.texture = texture
    node:attachProperty(clonedProp)
    node:updateProperties()
end

---@param id string The object ID of the reference to find
---@param cell tes3cell|nil The cell to search in. Defaults to the player's cell
---@return tes3reference|nil The reference with the given ID, or nil if not found
function common.findInCell(id, cell)
    cell = cell or tes3.player.cell
    for ref in cell:iterateReferences() do
        if ref.baseObject.id:lower() == id:lower() then
            return ref
        end
    end
end

---@param sceneNode niNode
function common.isNodeVisible(sceneNode)
    return sceneNode ~= nil
    and not sceneNode:isAppCulled()
    and not sceneNode:isFrustumCulled(tes3.worldController.worldCamera.cameraData.camera)
end


---@param target tes3reference
function common.pickUp(target)
    tes3.addItem({
        reference = tes3.player,
        item = target.object --[[@as JOP.tes3itemChildren]],
        count = 1,
        itemData = target.itemData,
    })
    target.itemData = nil
    target:delete()
end

local cellRegionCache = {}
function common.getRegion()
    local playerCell = tes3.player.cell
    if (not playerCell) then
        return
    end

    -- Does the current cell have a region?
    local playerCellRegion = playerCell.region
    if (playerCellRegion) then
        return playerCellRegion
    end

    -- Did we already find an answer last time?
    local cacheHit = cellRegionCache[playerCell]
    if (cacheHit) then
        return cacheHit
    end

    -- Look to see if anywhere exits to a place with a region.
    for ref in playerCell:iterateReferences(tes3.objectType.door) do
        local destination = ref.destination
        if (destination) then
            local destinationCell = destination.cell

            -- Does this cell have a region?
            local destinationRegion = destinationCell.region
            if (destinationRegion) then
                cellRegionCache[playerCell] = destinationRegion
                return destinationRegion
            end

            -- Does it point to a cell whose region we know?
            local destinationCacheHit = cellRegionCache[destinationCell]
            if (destinationCacheHit) then
                cellRegionCache[playerCell] = destinationCacheHit
                return destinationCacheHit
            end
        end
    end

    -- Still nothing? Just use the last exterior region if we can, but don't store it as reliable.
    local lastExterior = tes3.dataHandler.lastExteriorCell
    if (lastExterior) then
        return lastExterior.region
    end
end


return common