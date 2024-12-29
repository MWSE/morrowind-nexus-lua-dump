local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("main")
local Interop = require("mer.joyOfPainting")

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

--Add Interop to dialogue environments
event.register(tes3.event.dialogueEnvironmentCreated, function(e)
    ---@class mwseDialogueEnvironment
    local env = e.environment
    env.JoyOfPainting = Interop
end)


event.register(tes3.event.initialized, function()
    logger:debug("Initialising activators")
    initAll("activators")
    logger:info("Initialized v%s", common.getVersion())
end, { priority = 200 })

