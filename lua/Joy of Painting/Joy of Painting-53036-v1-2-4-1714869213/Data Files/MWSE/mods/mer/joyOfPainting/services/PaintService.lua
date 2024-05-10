local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaintService")

local PaintService = {}

function PaintService.createTexture(texture)
    local path = PaintService.getPaintingTexturePath(texture)
    if not tes3.getFileExists(path) then
        logger:warn("Painting texture '%s' does not exist", path)
        return nil
    end
    return niSourceTexture.createFromPath(path, false)
end

function PaintService.createIcon(texture)
    local path = "Icons\\" .. PaintService.getPaintingIconPath(texture)
    logger:debug("Creating icon from path %s", path)
    return niSourceTexture.createFromPath(path, true)
end

---Returns the path of the given texture file, relative to the Data Files directory
function PaintService.getPaintingTexturePath(texture)
    --Check the file exists
    local path = "Textures\\jop\\p\\" .. texture
    return path
end

function PaintService.getSavedPaintingDimensions(image)
    local aspectRatio = config.frameSizes[image.canvasConfig.frameSize].aspectRatio
    local savedImageSize = config.mcm.savedPaintingSize

    local width
    local height
    if image.canvasConfig.textureWidth > image.canvasConfig.textureHeight then
        width = savedImageSize * aspectRatio
        height = savedImageSize
    else
        width = savedImageSize
        height = savedImageSize / aspectRatio
    end
    return width, height
end

function PaintService.getSavedPaintingIndex(artStyle)
    local index = config.mcm.savedPaintingIndexes[artStyle.name]
    if not index then
        index = 1
        config.mcm.savedPaintingIndexes[artStyle.name] = index
        config:save()
    end
    return index
end

function PaintService.incrementSavedPaintingIndex(artStyle)
    local index = PaintService.getSavedPaintingIndex(artStyle)
    local nextIndex = index + 1
    if index >= config.mcm.maxSavedPaintings then
        nextIndex = 1
    end
    config.mcm.savedPaintingIndexes[artStyle.name] = nextIndex
    config:save()
    return nextIndex
end

---@param artStyle JOP.ArtStyle
---@return string # The path (relative to Data Files) of the full resolution saved painting
function PaintService.getSavedPaintingPath(artStyle)
    local index = PaintService.getSavedPaintingIndex(artStyle)
    if not index then
        index = 1
        config.mcm.savedPaintingIndexes[artStyle.name] = index
    end
    return string.format("Textures\\jop\\saved\\%s\\%s.png",
        artStyle.name, index)
end


function PaintService.getPaintingIconPath(texture)
    return "jop\\p\\" .. texture
end

function PaintService.getSketchTexture()
    return config.locations.sketchTexture
end

function PaintService.getPaintingDimensions(canvasId, maxHeight)
    logger:debug("Getting painting dimensions for %s. Max height: %s",
        canvasId, maxHeight)
    local canvasData = config.canvases[canvasId]
    local textureHeight = math.min(canvasData.textureHeight, maxHeight)

    local frameSize = config.frameSizes[canvasData.frameSize]
    if not frameSize then
        logger:error("Frame Size '%s' is not registered.", canvasData.frameSize)
        return
    end
    local ratio = frameSize.aspectRatio

    local height = textureHeight
    local width = textureHeight * ratio
    return {
        width = width,
        height = height
    }
end

return PaintService