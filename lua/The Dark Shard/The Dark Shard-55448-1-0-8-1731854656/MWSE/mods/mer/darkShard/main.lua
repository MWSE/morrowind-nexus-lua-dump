local common = require("mer.darkShard.common")
local logger = common.createLogger("Main")

--Initialise Modules
event.register(tes3.event.initialized, function()
    --if true then return end
    logger:info("Executing Integrations")
    common.initAll("mer/darkShard/integrations")
    logger:info("Executing Modules")
    common.initAll("mer/darkShard/modules")
    logger:info("Initialized The Dark Shard v%s", common.getVersion())

end, { priority = 100})

require("mer.darkShard.mcm")