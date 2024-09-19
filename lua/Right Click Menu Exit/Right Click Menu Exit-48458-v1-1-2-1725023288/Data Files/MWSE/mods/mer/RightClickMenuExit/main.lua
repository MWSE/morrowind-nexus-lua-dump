
local common = require("mer.RightClickMenuExit.common")
local logger = common.createLogger("main")

event.register("initialized", function()
    common.initAll("mer/RightClickMenuExit/modules")
    common.initAll("mer/RightClickMenuExit/integrations")
    logger:info("Initialized Right Click Menu Exit v%s", common.getVersion())
end)