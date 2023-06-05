local log = require("chantox.LeechFx.log")
require("chantox.LeechFx.health")
require("chantox.LeechFx.magicka")
require("chantox.LeechFx.fatigue")

local function onInitialized()
    log:info("Initialized.")
end
event.register(tes3.event.initialized, onInitialized)
