local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("DependencyManager")
--local DependencyManager = require("Metadata.DependencyManager")

-- if config.metadata.dependencies then
--     local dependencyManager = DependencyManager.new{
--         luaMod = "mer.joyOfPainting",
--         logger = logger,
--     }
--     event.register(tes3.event.initialized, function()
--         dependencyManager:checkDependencies()
--     end)
-- end
