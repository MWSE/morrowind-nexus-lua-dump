local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Frame")

local Frame = {
    classname = "Frame",
}

--[[
    Register a frame size, which allows canvases to have the right frame
]]
function Frame.registerFrameSize(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:assert(type(e.width) == "number", "width must be a number")
    logger:assert(type(e.height) == "number", "aspectRatio.height must be a number")
    logger:debug("Registering frame size %s", e.id)
    e.id = e.id:lower()
    config.frameSizes[e.id] = table.copy(e, {
        aspectRatio = e.width / e.height,
    })
    assert(math.isclose(config.frameSizes[e.id].aspectRatio, e.width / e.height) )
end

function Frame.registerFrame(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:assert(type(e.frameSize) == "string", "frameSize must be a string")
    logger:debug("Registering frame %s", e.id)
    e.id = e.id:lower()
    config.frames[e.id] = table.copy(e, {})
end

function Frame.isFrame(item)
    return config.frames[item.id:lower()] ~= nil
end

function Frame.getFrameConfig(item)
    return config.frames[item.id:lower()]
end


return Frame