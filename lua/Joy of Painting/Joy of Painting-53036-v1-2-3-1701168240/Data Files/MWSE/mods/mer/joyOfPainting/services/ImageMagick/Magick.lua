--An async api for ImageMagick
---@class JOP.Magick
---@field name string The name of the magick command being built. Used for logging.
---@field command string The magick command to be executed.
local Magick = {
    magickPath = "magick"
}
local Async = require("mer.joyOfPainting.services.Async")
local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Magick")
local PaintService = require("mer.joyOfPainting.services.PaintService")

function Magick.setMagickPath(newPath)
    logger:debug("Setting magick path to %s", newPath)
    Magick.magickPath = newPath
end

---@return JOP.Magick
function Magick:new(commandName)
    local self = {
        name = commandName or "",
        command = "magick"
    }
    setmetatable(self, { __index = Magick })
    return self
end


function Magick:log(logLevel, message, ...)
    logger[logLevel:lower()](logger, message, ...)
    return self
end

---@return JOP.Magick
--Begins a magick command, setting the command to "magick".
function Magick:magick()
    self.command = self.magickPath
    return self
end

---@return JOP.Magick
--Add a parameter to the command, wrapped in quotes to prevent OS specific commandline issues.
function Magick:param(filename)
    self.command = string.format('%s "%s"', self.command, filename)
    return self
end

---@return JOP.Magick
--Superimposes one image over the other and saves the new to a target location.
function Magick:composite(gravity, overlay, original)
    self.command = string.format('magick -gravity "%s" ( "%s" "%s" -composite ) ',
        gravity, original, overlay)
    return self
end

---@param baseTexture string The texture to place under the current texture
---@param width number The width of the final image
---@param height number The height of the final image
---@param baseTextureRotation number The rotation of the base texture, in degrees. Defaults to 0.
function Magick:compositeClone(baseTexture, width, height, baseTextureRotation)
    local resizeText = (width and height) and string.format('-resize "%sx%s!" ', width, height) or ""
    local rotateText = baseTextureRotation
        and baseTextureRotation ~= 0
        and string.format('-rotate "%s" ', baseTextureRotation)
        or ""
    self.command = string.format(
        '%s ( "%s" %s %s) +swap -compose atop -composite',
        self.command,
        baseTexture,
        rotateText,
        resizeText
    )
    return self
end


---@return JOP.Magick
--Resizes an image to a given width and height, maintaining aspect ratio.
function Magick:resize(width, height)
    if width > height then
        self.command = string.format('%s -resize "%s^x%s" ', self.command, width, height)
    else
        self.command = string.format('%s -resize "%sx%s^" ', self.command, width, height)
    end
    return self
end

---@return JOP.Magick
--Resizes an image to a given width and height, ignoring aspect ratio.
function Magick:resizeHard(width, height)
    self.command = string.format('%s -resize "%sx%s!" ', self.command, width, height)
    return self
end

---@return JOP.Magick
--Sets the gravity property.
function Magick:gravity(val)
    self.command = string.format('%s -gravity %s ', self.command, val)
    return self
end

---@return JOP.Magick
--Sets the filter property.
function Magick:filter(filterType)
    self.command = string.format('%s -filter "%s" ', self.command, filterType)
    return self
end

function Magick:trim()
    self.command = string.format('%s -trim ', self.command)
    return self
end

---@return JOP.Magick
--Crops the image to the given width and height.
function Magick:crop(width, height)
    self.command = string.format('%s -crop "%sx%s+0+0" ', self.command, width, height)
    return self
end

---@return JOP.Magick
--Removes paging information from the image.
function Magick:repage()
    self.command = string.format('%s +repage ', self.command)
    return self
end

---@return JOP.Magick
--Adds an oil paint effect to the image.
function Magick:paint(size)
    if size and size >= 1 then
        self.command = string.format('%s -paint %s ', self.command, size)
    end
    return self
end

function Magick:blur(size)
    if size and size >= 1 then
        self.command = string.format('%s -blur %s ', self.command, size)
    end
    return self
end

function Magick:greyscale()
    self.command = string.format('%s -colorspace gray ', self.command)
    return self
end

function Magick:sketch()
    self.command = string.format('%s ( +clone -tile "%s" -draw "color 0,0 reset" +clone +swap -compose color_dodge -composite ) -fx "u*.2+v*.8" ',
        self.command, PaintService.getSketchTexture())
    return self
end

function Magick:charcoal(thickness)
    thickness = thickness or 1
    self.command = string.format('%s -charcoal %s ', self.command, thickness)
    return self
end

function Magick:removeWhite(fuzz)
    self.command = string.format('%s -fuzz %s%% -transparent white ',
        self.command, fuzz)
    return self
end

function Magick:removeWhite_1(fuzz)
    self.command = string.format('%s -fuzz %s%% +transparent black -alpha extract -threshold 0 -negate -transparent white +level-colors black ',
        self.command, fuzz)
    return self
end

function Magick:removeWhite_2(_)
    self.command = string.format('%s -alpha copy -channel alpha -negate +channel -fx "#000" ',
        self.command)
    return self
end

function Magick:removeWhite_3()
    self.command = string.format('%s -negate -alpha copy -channel rgb -fx "0" ',
        self.command)
    return self
end

function Magick:transparent(percent)
    local level = (100 - percent) / 100
    self.command = string.format("%s -channel A -evaluate multiply %s -negate +channel ",
        self.command, level)
    return self
end

---@return JOP.Magick
--Adds a transparent border around the image.
function Magick:border(x, y)
    self.command = string.format('%s -bordercolor transparent -border "%sx%s" ', self.command, x, y)
    return self
end

---@return JOP.Magick
--Adjust the brightness and contrast of the image.
function Magick:brightnessContrast(brightness, contrast)
    self.command = string.format('%s -brightness-contrast "%sx%s" ', self.command, brightness, contrast)
    return self
end

---@return JOP.Magick
--Sets the brightness and contrast to stretch over all values.
function Magick:autoLevel()
    self.command = string.format('%s -auto-level ', self.command)
    return self
end

function Magick:autoGamma()
    self.command = string.format('%s -auto-gamma ', self.command)
    return self
end

function Magick:normalize()
    self.command = string.format('%s -normalize ', self.command)
    return self
end

function Magick:whiteBalance()
    self.command = string.format('%s -white-balance ', self.command)
    return self
end

function Magick:draw(shape, color, x0, y0, x1, y1)
    self.command = string.format('%s -fill "%s" -draw "%s %s,%s %s,%s" ',
        self.command, color, shape, x0, y0, x1, y1)
    return self
end

function Magick:removeTransparency(bgColor)
    self.command = string.format('%s -background "%s" -alpha remove ', self.command, bgColor)
    return self
end

function Magick:formatDDS()
    self.command = string.format('%s -format dds -define dds:mipmaps=5 -define dds:compression=dxt5 ', self.command)
    return self
end


---@return JOP.Magick
-- Asynchronously execute the ImageMagick command, then call the callback function when it is finished.
function Magick:execute(callback)
    logger:debug("[%s] Executing command: %s", self.name, self.command)
    Async.execute(self.command, callback)
    return self
end

return Magick