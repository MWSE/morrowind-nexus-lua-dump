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
    --check if 'Data Files\ImageMagick\magick.exe' exists
    local magickPath = "Data Files/ImageMagick/magick.exe"
    if lfs.attributes(magickPath) then
        Magick.setMagickPath(magickPath)
    else
        --check if ImageMagick exists in PATH
        local magickExists = os.execute("magick -version")
        if magickExists then
            Magick.setMagickPath("magick")
        else
            logger:error("Image magick is not installed")
            timer.frame.delayOneFrame(function()
                tes3.messageBox{
                    message = "Joy of Painting ERROR: ImageMagick is not installed.",
                    buttons = { "OK" }
                }
            end)
        end
    end
end


event.register(tes3.event.initialized, function()
    setMagickPath()
    logger:debug("Initialising activators")
    initAll("activators")
    logger:info("Initialized v%s", common.getVersion())
end, { priority = 200 })

