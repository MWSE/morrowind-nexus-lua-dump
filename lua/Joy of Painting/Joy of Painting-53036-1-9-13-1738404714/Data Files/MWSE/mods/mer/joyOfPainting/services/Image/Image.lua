---@class JOP.color
---@field r number?
---@field g number?
---@field b number?

--[[
    This class is used for executing asynchronous
    commands to convert images.
]]
---@class JOP.Image
---@field screenshotPath string? The path to the intial screenshot, relative to Morrowind (so it should start with "Data Files")
---@field savedPaintingPath string The path to the full-res painting image
---@field paintingPath string? The path to the resized painting texture used in-game
---@field iconPath string? The icon of the painting
---@field framedIconPath string? The framed icon of the painting
---@field canvasConfig JOP.Canvas? The canvasConfig used for the painting
---@field iconSize integer? The size of the icon
---@field iconBorder integer? The transparent padding around the icon
---@field framePath string? The icon of the picture frame
---@field color JOP.color? The average color of the painting
---@field detailLevel number? The level of detail, based on painting skill
local Image = {}
Image.blocked = false

local PaintService = require("mer.joyOfPainting.services.PaintService")
local config = require("mer.joyOfPainting.config")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Image")
local imageLib = include("imagelib")




---@param data JOP.Image
---@return JOP.Image
function Image:new(data)
    local self = data
    setmetatable(self, { __index = Image })
    return self
end

function Image:start(callback)
    if Image.blocked then
        logger:error("Image is blocked, skipping")
        return
    end
    Image.blocked = true
    if callback then callback() end
end

--Unblock Image processing
function Image:finish(callback)
    Image.blocked = false
    if callback then callback() end
end


--[[
    This function takes a screenshot of the current
    game viewport, and executes the callback once it
    detects the new image has appeared.
]]
---@param callback function
function Image:takeScreenshot(callback)
    logger:debug("[takeScreenshot] Taking screenshot and waiting for file to appear")

    mge.saveScreenshot{ path = config.locations.screenshot}

    ---@type mwseTimer
    local waitForScreenshotTimer
    waitForScreenshotTimer = timer.start{
        duration = 0.01,
        type = timer.real,
        iterations = 200,
        callback = function()
            if lfs.fileexists(config.locations.screenshot) then
                logger:debug("[takeScreenshot] Screenshot found, stopping timer")
                waitForScreenshotTimer:cancel()
                self.screenshotPath = config.locations.screenshot
                if callback then callback() end
            end
        end
    }
end

function Image:createPaintingTexture(next)
    local image = imageLib.Image.fromPath(self.savedPaintingPath)
    local canvasTexturePath = common.getCanvasTexture(self.canvasConfig.canvasTexture)
    local canvasImage = imageLib.Image.fromPath(canvasTexturePath)
    canvasImage:resizeHard(self.canvasConfig.textureWidth, self.canvasConfig.textureHeight)
    --Apply as many rotations as needed
    if self.canvasConfig.baseRotation and self.canvasConfig.baseRotation > 0 then
        local rotations = math.floor(self.canvasConfig.baseRotation / 90)
        for _ = 1, rotations do
            canvasImage:rotate90()
        end
    end
    image:applyAlphaMask(canvasImage)
    image:save(self.paintingPath)
    if next then next() end
end

function Image:createWallpaper(next)
    local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(self)
    local image = imageLib.Image.fromPath(self.screenshotPath)
    image:trim(0)
    image:resizeHard(savedWidth, savedHeight)
    image:save(self.savedPaintingPath)
    if next then next() end
end

function Image:deleteScreenshot(next)
    assert(self.screenshotPath, "image.screenshotPath is nil")
    if lfs.fileexists(self.screenshotPath) then
        logger:debug("Deleting old screenshot file: %s", self.screenshotPath)
        assert(os.remove(self.screenshotPath),
            string.format("unable to delete file '%s'", self.screenshotPath))
    else
        logger:warn("No screenshot file to delete: %s", self.screenshotPath)
    end
    if next then next() end
end

---@param self JOP.Image
---@param next function
function Image:createIcon(next)
    logger:debug("[createIcon] Creating icon %s with width: %s height: %s, frameSize = %s",
        self.paintingPath, self.iconSize, self.iconSize, self.canvasConfig.frameSize)
    local aspectRatio = PaintService.getAspectRatio(self.canvasConfig)
    local iconWidth, iconHeight
    local iconInnerSize = self.iconSize - self.iconBorder * 2
    if self.canvasConfig.textureWidth > self.canvasConfig.textureHeight then
        iconWidth = iconInnerSize
        iconHeight = iconInnerSize / aspectRatio
    else
        iconHeight = iconInnerSize
        iconWidth = iconInnerSize * aspectRatio
    end
    --round to even numbers
    iconWidth = math.floor(iconWidth / 2) * 2
    iconHeight = math.floor(iconHeight / 2) * 2

    local image = imageLib.Image.fromPath(self.paintingPath)
    image:resizeHard(iconWidth, iconHeight)
    image:intoIcon(-1, -1)
    image:save(self.iconPath)
    if next then next() end
end


--reset block state in case game was loaded in the middle of processing
event.register("loaded", function()
    Image.blocked = false
end)

return Image