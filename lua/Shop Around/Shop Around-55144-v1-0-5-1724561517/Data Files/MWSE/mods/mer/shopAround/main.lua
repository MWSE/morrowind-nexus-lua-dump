local common = require("mer.shopAround.common")
local logger = common.createLogger("Main")

--Initialise Modules
event.register(tes3.event.initialized, function()
    common.initAll("mer/shopAround/modules")
    logger:info("Initialized Shop Around v%s", common.getVersion())
end)

--Initialise MCM
require("mer.shopAround.mcm")