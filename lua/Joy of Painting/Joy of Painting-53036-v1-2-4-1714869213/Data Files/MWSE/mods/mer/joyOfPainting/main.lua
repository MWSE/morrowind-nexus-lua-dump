local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("main")
local Magick = require("mer.joyOfPainting.services.ImageMagick.Magick")

require("mer.joyOfPainting.mcm")

local function initAll(path)
    path = "Data Files/MWSE/mods/mer/joyOfPainting/" .. path .. "/"
    for file in lfs.dir(path) do
        if common.isLuaFile(file) and not common.isInitFile(file) then
            logger:debug("Executing file: %s", file)
            dofile(path .. file)
        end
    end
end

logger:debug("Initialising Event Handlers")
initAll("eventHandlers")
logger:debug("Initialising Interops")
initAll("interops")

local function setMagickPath()
    local paths = {
        "Data Files/ImageMagick/magick.exe",
        "Data Files/MWSE/lib/ImageMagick/magick.exe"
    }
    for _, path in ipairs(paths) do
        if lfs.attributes(path) then
            Magick.setMagickPath(path)
            return
        end
    end
    Magick.setMagickPath("magick")
end


event.register(tes3.event.initialized, function()
    setMagickPath()
    logger:debug("Initialising activators")
    initAll("activators")
    logger:info("Initialized v%s", common.getVersion())
end, { priority = 200 })

