---@class JOP.color
---@field r number?
---@field g number?
---@field b number?

--[[
    This class is used for executing asynchronous
    commands to convert images.
]]
---@class JOP.Image
---@field screenshotPath string? The path to the intial screenshot
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

local Magick = require("mer.joyOfPainting.services.ImageMagick.Magick")
local config = require("mer.joyOfPainting.config")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Image")

Image.magick = Magick

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

function Image:createPaintingTexture(callback)
    --[[
        - find the savedPaintingPath image
        - resize it with :resizeHard(image.canvasConfig.textureWidth, image.canvasConfig.textureHeight)
        - save it to image.paintingPath
        ]]
    local textureWidth = self.canvasConfig.textureWidth
    local textureHeight = self.canvasConfig.textureHeight
    logger:debug("[createPaintingTexture] Creating painting texture %s with width: %s height: %s",
        self.paintingPath, textureWidth, textureHeight)
    Magick:new("createPaintingTexture")
        :magick()
        :formatDDS()
        :param(self.savedPaintingPath)
        :resizeHard(textureWidth, textureHeight)
        :param(self.paintingPath)
        :execute(callback)
end


function Image:deleteScreenshot(callback)
    assert(self.screenshotPath, "image.screenshotPath is nil")
    if lfs.fileexists(self.screenshotPath) then
        logger:debug("Deleting old screenshot file: %s", self.screenshotPath)
        assert(os.remove(self.screenshotPath),
            string.format("unable to delete file '%s'", self.screenshotPath))
    else
        logger:warn("No screenshot file to delete: %s", self.screenshotPath)
    end
    if callback then callback() end
end

---@param self JOP.Image
---@param callback function
function Image:createIcon(callback)
    logger:debug("[createIcon] Creating icon %s with width: %s height: %s, frameSize = %s",
        self.paintingPath, self.iconSize, self.iconSize, self.canvasConfig.frameSize)
    local aspectRatio = config.frameSizes[self.canvasConfig.frameSize].aspectRatio
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

    local borderWidth = (self.iconSize - iconWidth) / 2
    local borderHeight = (self.iconSize - iconHeight) / 2

    logger:debug("[createIcon] iconWidth: %s iconHeight: %s borderWidth: %s borderHeight: %s",
        iconWidth, iconHeight, borderWidth, borderHeight)

    Magick:new("createIcon")
    :magick()
    :param(self.paintingPath)
    :gravity("Center")
    :resizeHard(iconWidth, iconHeight)
    :crop(iconWidth, iconHeight)
    :border(borderWidth, borderHeight)
    :repage()
    :param(self.iconPath)
    :execute(callback)
end

function Image:createFramedIcon(callback)
    logger:debug("[createFramedIcon] Adding frame to icon at %s",
    self.framedIconPath)
    Magick:new("createFramedIcon")
        :composite("center", self.framePath, self.iconPath)
        :param(self.framedIconPath)
        :execute(callback)
end

function Image:calculateAverageColor(callback)
    logger:debug("[calculateAverageColor] Calculating average color of %s",
        self.paintingPath)

    local pixelPath = config.locations.iconsDir .. "pixel.txt"
    Magick:new("calculateAverageColor")
    :magick()
    :param(self.paintingPath)
    :resize(1, 1)
    :param(pixelPath)
    :execute(function()
        local pixel = io.open(pixelPath, "r")
        if not pixel then
            logger:error("[getAverageColor] Failed to open %s", pixelPath)
            Image.blocked = false
            return
        end

        --[[
            A single pixel texture saved as a .txt file looks like this:

            # ImageMagick pixel enumeration: 1,1,0,255,srgb
            0,0: (150,170,179)  #96AAB3  srgb(58.9545%,66.6869%,70.062%)

            We want the values on the second line, i.e (150,170,179)
        ]]
        ---@type string
        local imageInfo = pixel:read("*all")
        logger:debug("%s", imageInfo)
        local _, positionStart = imageInfo:find("0,0: (", 1, true)
        local positionEnd = imageInfo:find(")", positionStart, true)
        local colorVals = imageInfo:sub(positionStart+1, positionEnd-1):split(",")
        ---@type JOP.color
        self.color = {
            r = tonumber(colorVals[1]),
            g = tonumber(colorVals[2]),
            b = tonumber(colorVals[3]),
        }
        pixel:close()
        os.remove(pixelPath)
        if callback then callback() end
    end)
end

--reset block state in case game was loaded in the middle of processing
event.register("loaded", function()
    Image.blocked = false
end)

return Image