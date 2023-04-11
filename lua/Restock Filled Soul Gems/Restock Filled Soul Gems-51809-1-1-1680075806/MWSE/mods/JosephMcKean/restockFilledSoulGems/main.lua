local config = require("JosephMcKean.restockFilledSoulGems.config")
local logger =
    require("JosephMcKean.restockFilledSoulGems.logging").createLogger("main")

local function onInitialized(e)
    if config.modEnabled then
        logger:debug("initialized.")
        require("JosephMcKean.restockFilledSoulGems.restockFilledSoulGems")
    end
end
event.register("initialized", onInitialized)

require("JosephMcKean.restockFilledSoulGems.mcm")
