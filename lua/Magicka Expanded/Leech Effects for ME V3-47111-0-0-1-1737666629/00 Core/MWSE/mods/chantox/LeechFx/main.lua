local log = require("chantox.LeechFx.log")

local framework = include("OperatorJack.MagickaExpanded")
-- Check Magicka Expanded framework.
if (framework == nil) then
    log:error("Magicka Expanded framework is not installed!")
    return nil
end

require("chantox.LeechFx.health")
require("chantox.LeechFx.magicka")
require("chantox.LeechFx.fatigue")

local function onInitialized()
    log:info("Initialized.")
end
event.register(tes3.event.initialized, onInitialized)
