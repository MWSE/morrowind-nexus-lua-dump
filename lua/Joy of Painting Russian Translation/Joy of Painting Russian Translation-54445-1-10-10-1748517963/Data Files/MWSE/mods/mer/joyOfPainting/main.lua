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
    -- Check for imagelib plugin.
    local imagelib = include("imagelib")
    if (imagelib == nil) then
        local warningMsg = "MWSE/lib/imagelib.dll не найден. Возможно, ваш менеджер модов может не устанавливать файлы .dll, и вам придется установить его вручную."
        logger:warn(warningMsg)
        tes3.messageBox("[Радость рисования]: " .. warningMsg)
        return
    end

    -- Ensure paper names align
    local originalPaper = tes3.getObject("sc_paper plain")
    local horizontalPaper = tes3.getObject("jop_paper_h")
    horizontalPaper.name = originalPaper.name

    logger:debug("Initialising activators")
    initAll("activators")
    logger:info("Initialized v%s", common.getVersion())
end, { priority = 200 })

