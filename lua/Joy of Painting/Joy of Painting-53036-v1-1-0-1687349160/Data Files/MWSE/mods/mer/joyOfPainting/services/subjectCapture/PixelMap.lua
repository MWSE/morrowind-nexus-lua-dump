local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("PixelMap")

local ffi = require("ffi")
ffi.cdef [[
    typedef struct {
        unsigned char b;
        unsigned char g;
        unsigned char r;
        unsigned char a;
    } Pixel;

    typedef struct {
        void* vtable;
        int refCount;
        unsigned int format;
        unsigned int channelMasks[4];
        unsigned int bitsPerPixel;
        unsigned int compareBits[2];
        void* palette;
        Pixel* pixels;
        unsigned int* widths;
        unsigned int* heights;
        unsigned int* offsets;
        unsigned int mipMapLevels;
        unsigned int bytesPerPixel;
        unsigned int revisionID;
    } NiPixelData;
]]

---@class JOP.PixelMap.new.params
---@field pixelData niPixelData
---@field aspectRatio number  The aspect ratio of the viewport, calculated as width/height
---@field viewportScale number The size of the viewport compared to the full screen size. The viewport is expanded to fill the screen, then the width and height are multiplied by this value to get the viewport size.


---A class for helping iterate through pixels in a niPixelData
---@class JOP.PixelMap
---@field pixels table The array of pixels
---@field width number The width of the pixelData
---@field height number The height of the pixelData
---@field totalViewportPixels number The total number of pixels in the pixelData
---@field viewportWidth number The width of the viewport
---@field viewportHeight number The height of the viewport
---@field xOffset number The x offset of the viewport
---@field yOffset number The y offset of the viewport
local PixelMap = {}

---@param e JOP.PixelMap.new.params
---@return JOP.PixelMap
function PixelMap.new(e)
    local self = setmetatable({}, { __index = PixelMap })

    local ptr = mwse.memory.convertFrom.niObject(e.pixelData) ---@diagnostic disable-line
    local pixelDataFFI = ffi.cast("NiPixelData*", ptr)[0]

    self.width = pixelDataFFI.widths[0]
    self.height = pixelDataFFI.heights[0]


    logger:debug("Image size: %d x %d", self.width, self.height)
    self.pixels = pixelDataFFI.pixels
    self:calculateViewport(e.aspectRatio, e.viewportScale)
    return self
end

---Iterates through the pixels in the pixelData
function PixelMap:calculateViewport(aspectRatio, viewportScale)

    local screenX, screenY = tes3ui.getViewportSize()
    local screenRatio = screenX / screenY
    local imageRatio = self.width / self.height
    logger:debug("aspectRatio: %f", aspectRatio)
    logger:debug("screenRatio: %f", screenRatio)
    logger:debug("viewportScale: %f", viewportScale)
    logger:debug("imageRatio: %f", imageRatio)

    local viewportWidth, viewportHeight
    if (aspectRatio * screenRatio > screenRatio ) then
        logger:debug("Screen is wider than the given width and height")
        -- If the screen is wider than the given width and height,
        -- the rectangle should stretch to the width of the screen
        viewportWidth = self.width
        viewportHeight = self.width / imageRatio / aspectRatio * screenRatio
    else
        --Todo
        logger:debug("Screen is taller than the given width and height")
        -- If the screen is taller than the given width and height,
        -- the rectangle should stretch to the height of the screen
        viewportWidth = self.height * imageRatio * aspectRatio / screenRatio
        viewportHeight = self.height
    end
    --Scale down by the viewport ratio
    self.viewportWidth = math.floor(viewportWidth * viewportScale)
    self.viewportHeight = math.floor(viewportHeight * viewportScale)
    self.totalViewportPixels = self.viewportWidth * self.viewportHeight
    self.totalEdgePixels = (self.viewportWidth * 2) + (self.viewportHeight * 2) - 4
    self.xOffset = math.floor((self.width - self.viewportWidth) / 2)
    self.yOffset = math.floor((self.height - self.viewportHeight) / 2)
    logger:debug("Viewport size: w=%d x h=%d", self.viewportWidth, self.viewportHeight)
end

function PixelMap:getPixel(x, y)
    local offx = x + self.xOffset
    local offy = y + self.yOffset
    local i = (self.width * offy) + offx
    if i < 0 or i > self.width * self.height then
        error(string.format("Pixel index out of bounds: %d", i))
    end
    local pixel = self.pixels[i]
    return pixel, i
end

function PixelMap:isEdge(x, y)
    if y == 0 or y == self.viewportHeight - 1 then
        return true
    end
    if x == 0 or x == self.viewportWidth - 1 then
        return true
    end
end

function PixelMap:isActivePixel(pixel)
    return pixel.b >= 128
end

---@class JOP.PixelMap.countPixels.data
---@field active number The number of active pixels
---@field total number The total number of pixels in the viewport
---@field activeEdges number The number of active pixels on the edge of the viewport
---@field totalEdges number The total number of pixels on the edge of the viewport


---@return JOP.PixelMap.countPixels.data
function PixelMap:getPixelCountData()
    local activeEdges = 0
    local activeCount = 0
    for y = 0, self.viewportHeight -1 do
        for x = 0, self.viewportWidth -1 do
            local pixel = self:getPixel(x, y)
            local isActive = self:isActivePixel(pixel)


            if isActive then
                activeCount = activeCount + 1
            else
                pixel.r = 100
            end
            if self:isEdge(x, y) then
                if isActive then
                    activeEdges = activeEdges + 1
                end
                pixel.g = 255
            end
        end
    end
    logger:debug("Active pixels: %d", activeCount)
    return {
        active = activeCount,
        total = self.totalViewportPixels,
        activeEdges = activeEdges,
        totalEdges = self.totalEdgePixels,
    }
end


return PixelMap